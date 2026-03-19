// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';

import 'armadillo_drag_target.dart';
import 'armadillo_overlay.dart';
import 'display_mode.dart';
import 'optional_wrapper.dart';
import 'panel.dart';
import 'panel_resizing_model.dart';
import 'place_holder_story.dart';
import 'simulated_fractionally_sized_box.dart';
import 'simulated_padding.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_data.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_panels_model.dart';
import 'story_drag_transition_model.dart';
import 'story_full_size_simulated_sized_box.dart';
import 'story_model.dart';
import 'story_positioned.dart';

final Color _kStoryBackgroundColor = Colors.grey[300]!;

const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Set to true to give the focused tab twice the space as an unfocused tab.
const bool _kGrowFocusedTab = false;

/// Displays up to four stories in a grid-like layout.
class StoryPanels extends StatelessWidget {
  /// The cluster whose stories will be displayed.
  final StoryCluster storyCluster;

  /// The progress of the cluster coming into focus.
  final double focusProgress;

  /// The overlay to use for this cluster's draggable.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// The size the cluster's widget should be.
  final Size currentSize;

  /// If true, this StoryPanel is currently being dragged
  final bool isBeingDragged;

  /// Constructor.
  StoryPanels({
    Key? key,
    required this.storyCluster,
    required this.focusProgress,
    required this.overlayKey,
    required this.currentSize,
    this.isBeingDragged = false,
  })  : assert(() {
          Panel.haveFullCoverage(
            storyCluster.stories
                .map(
                  (Story story) => story.panel,
                )
                .toList(),
          );
          return true;
        }()),
        super(key: key);

  /// Set elevation of this story cluster based on the state:
  /// * Dragged
  /// * Focused
  /// * InlinePreview
  /// * InlinePreviewHint
  /// * Nothing
  // ARMADILLAZARUS(parity): elevation can go negative during drag
  // transitions; PhysicalModel asserts >= 0.
  double _getElevation(double dragProgress) {
    double e;
    if (isBeingDragged) {
      e = Elevations.draggedStoryCluster * dragProgress;
    } else if (focusProgress > 0.0) {
      e = Elevations.focusedStoryCluster * focusProgress;
    } else {
      // This will progressively animate the the elevation of a story cluster
      // when it goes from the inlinePreview hint state to the full blown inline
      // preview state.
      e = (storyCluster.inlinePreviewScaleModel.value +
              storyCluster.inlinePreviewHintScaleModel.value) *
          Elevations.storyClusterInlinePreview /
          2.0;
    }
    return e.clamp(0.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<StoryClusterPanelsModel>(
        builder: (
          BuildContext context,
          Widget? child,
          StoryClusterPanelsModel storyClusterPanelsModel,
        ) =>
            _buildWidget(context),
      );

  Widget _buildWidget(BuildContext context) {
    /// Move placeholders to the beginning of the list when putting them in
    /// the stack to ensure they are behind the real stories in paint order.
    List<Story> sortedStories = new List<Story>.from(storyCluster.stories)
      ..sort(
        (Story a, Story b) => a.isPlaceHolder && !b.isPlaceHolder
            ? -1
            : !a.isPlaceHolder && b.isPlaceHolder
                ? 1
                : 0,
      );

    List<Widget> stackChildren = <Widget>[]..addAll(
        sortedStories.map(
          (Story story) {
            _setStoryBarPadding(
              story: story,
              width: currentSize.width,
            );

            return new StoryPositioned(
              storyBarMaximizedHeight: SizeModel.kStoryBarMaximizedHeight,
              focusProgress: focusProgress,
              displayMode: storyCluster.displayMode,
              isFocused: storyCluster.focusedStoryId == story.id,
              panel: story.panel,
              currentSize: currentSize,
              childContainerKey: story.positionedKey,
              child: new ScopedModelDescendant<StoryDragTransitionModel>(
                builder: (
                  BuildContext context,
                  Widget? child,
                  StoryDragTransitionModel storyDragTransitionModel,
                ) =>
                    _getStory(
                  context,
                  story,
                  currentSize,
                  storyDragTransitionModel.value,
                  focusProgress,
                  storyCluster.focusedStoryId == story.id,
                ),
              ),
            );
          },
        ),
      );

    return new Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: stackChildren,
    );
  }

  Widget _getStoryBarDraggableWrapper(
    BuildContext context,
    Story story,
    Widget? child,
  ) {
    bool onFirstHoverCalled = false;
    Map<StoryId, Panel> storyPanelsOnDrag = <StoryId, Panel>{};
    List<StoryId> storyListOrderOnDrag = <StoryId>[];
    DisplayMode? displayModeOnDrag;
    return new OptionalWrapper(
      // Don't allow dragging if we're the only story.
      useWrapper: storyCluster.realStories.length > 1 && focusProgress == 1.0,
      builder: (BuildContext context, Widget child) =>
          new ArmadilloLongPressDraggable<StoryClusterDragData>(
        key: story.clusterDraggableKey,
        overlayKey: overlayKey,
        data: new StoryClusterDragData(
          id: story.clusterId,
          // If a story bar is dragged such that the story is split from the
          // cluster, we need to do some special work to make the drag
          // feedback act as if we've hovered over a location which causes
          // the original layout to be previewed.
          onFirstHover: () {
            if (!onFirstHoverCalled) {
              onFirstHoverCalled = true;

              // Reset cluster to original stories (using the saved off map
              // of story ids to panels in onDragStarted) with a place
              // holder for the split story.
              // Mirror drag feedback with this.

              // 1. Add a placeholder for the split story.
              storyCluster.add(
                story: new PlaceHolderStory(associatedStoryId: story.id),
                withPanel: storyPanelsOnDrag[story.id]!,
                atIndex: storyListOrderOnDrag.indexOf(story.id),
              );

              // 2. Resize all story panels to match original values.
              for (StoryId storyId in storyPanelsOnDrag.keys
                  .where((StoryId storyId) => storyId != story.id)) {
                storyCluster.replaceStoryPanel(
                  storyId: storyId,
                  withPanel: storyPanelsOnDrag[storyId]!,
                );
              }

              // 3. Add placeholders to feedback cluster.
              StoryCluster? feedbackCluster =
                  StoryModel.of(context).getStoryCluster(story.clusterId);
              if (feedbackCluster == null) return;
              for (StoryId storyId in storyPanelsOnDrag.keys) {
                if (storyId != story.id) {
                  feedbackCluster.add(
                    story: new PlaceHolderStory(
                      associatedStoryId: storyId,
                    ),
                    withPanel: storyPanelsOnDrag[storyId]!,
                  );
                }
              }

              // 4. Have feedback cluster mirror panels of cluster.
              feedbackCluster
                ..replaceStoryPanel(
                  storyId: story.id,
                  withPanel: storyPanelsOnDrag[story.id]!,
                )

                // 5. Have feedback cluster mirror story order of cluster.
                ..mirrorStoryOrder(storyCluster.stories)

                // 6. Update feedback cluster display mode.
                ..displayMode = displayModeOnDrag ?? DisplayMode.panels;
            }
          },
          onNoTarget: () {
            // If we've no target we need to put everything back where it
            // was when we started dragging.

            // 1. Replace the place holder in this cluster with the original
            //    story.
            // 2. Restore story order.
            storyCluster
              ..removePreviews()
              ..add(
                story: story,
                withPanel: storyPanelsOnDrag[story.id]!,
                atIndex: storyListOrderOnDrag.indexOf(story.id),
              );

            // 3. Restore panels.
            for (StoryId storyId in storyPanelsOnDrag.keys) {
              storyCluster.replaceStoryPanel(
                storyId: storyId,
                withPanel: storyPanelsOnDrag[storyId]!,
              );
            }

            // 4. Remove the split story cluster from the cluster list.
            StoryModel.of(context).remove(
              StoryModel.of(context).getStoryCluster(story.clusterId)!,
            );
            StoryModel.of(context).clearPlaceHolderStoryClusters();
          },
        ),
        onDragStarted: () {
          RenderBox box = story.positionedKey.currentContext!
              .findRenderObject()! as RenderBox;

          // Store off panel configuration before splitting.
          storyPanelsOnDrag.clear();
          storyListOrderOnDrag.clear();
          for (Story story in storyCluster.stories) {
            storyPanelsOnDrag[story.id] = new Panel.from(story.panel);
            storyListOrderOnDrag.add(story.id);
          }
          displayModeOnDrag = storyCluster.displayMode;

          StoryModel.of(context).split(
            storyToSplit: story,
            from: storyCluster,
          );
          StoryClusterDragStateModel.of(context).addDragging(
            story.clusterId,
          );

          return box.size;
        },
        onDragEnded: () =>
            StoryClusterDragStateModel.of(context).removeDragging(
          story.clusterId,
        ),
        onDismiss: () {
          final c = StoryModel.of(context).getStoryCluster(story.clusterId);
          if (c != null) StoryModel.of(context).delete(c);
        },
        childWhenDragging: Nothing.widget,
        feedbackBuilder: (Offset localDragStartPoint, Size initialSize) {
          StoryCluster? storyCluster =
              StoryModel.of(context).getStoryCluster(story.clusterId);
          if (storyCluster == null) return const SizedBox.shrink();

          return new StoryClusterDragFeedback(
            key: storyCluster.dragFeedbackKey,
            overlayKey: overlayKey,
            storyCluster: storyCluster,
            localDragStartPoint: localDragStartPoint,
            initialSize: initialSize,
            initDx: -story.simulatedPaddingModel.left,
          );
        },
        child: child,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  Widget _getStory(
    BuildContext context,
    Story story,
    Size currentSize,
    double dragProgress,
    double focusProgress,
    bool isFocused,
  ) {
    double storyElevation = _getElevation(dragProgress);

    // Add extra elevation if the given story is a focused tab in the story
    // cluster with 2 or more stories
    double storyElevationWithTabs = storyElevation;
    if (storyCluster.displayMode == DisplayMode.tabs &&
        storyCluster.stories.length > 1 &&
        storyCluster.focusedStoryId == story.id) {
      storyElevationWithTabs += Elevations.focusedStoryTab;
    }

    story.storyBarFocus = (storyCluster.displayMode == DisplayMode.panels) ||
        (storyCluster.focusedStoryId == story.id);

    // TODO(SY-291): Remove the lerpDouble from 1.03 to 1.0 and
    // just use 1.0.  This was added to zoom the story in slightly
    // to hide Mondrain's drag bars.
    story.simulatedFractionallySizedBoxModel.target =
        (storyCluster.focusedStoryId == story.id ||
                storyCluster.displayMode == DisplayMode.panels)
            ? lerpDouble(1.03, 1.0, focusProgress)!
            : 0.0;

    return story.isPlaceHolder
        ? Nothing.widget
        : new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The story bar that pushes down the story.
              new SimulatedPadding(
                model: story.simulatedPaddingModel,
                width: currentSize.width,
                child: new GestureDetector(
                  onTap: () {
                    storyCluster.focusedStoryId = story.id;
                    // If we're in tabbed mode we want to jump the newly
                    // focused story's size to full size instead of animating
                    // it.
                    if (storyCluster.displayMode == DisplayMode.tabs) {
                      for (Story story in storyCluster.stories) {
                        bool storyFocused =
                            storyCluster.focusedStoryId == story.id;
                        story.simulatedFractionallySizedBoxModel
                            .jump(storyFocused ? 1.0 : 0.0);
                        if (storyFocused) {
                          story.positionedKey.currentState
                              ?.jumpFractionalHeight(1.0);
                        }
                      }
                    }
                  },
                  child: new ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: SizeModel.kStoryBarMaximizedHeight,
                    ),
                    child: _getStoryBarDraggableWrapper(
                      context,
                      story,
                      story.wrapWithModels(
                        child: new StoryBar(
                          story: story,
                          elevation: storyElevationWithTabs,
                          borderRadius: _getStoryBarBorderRadius(story),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The story itself.
              new Expanded(
                child: new SimulatedFractionallySizedBox(
                  model: story.simulatedFractionallySizedBoxModel,
                  alignment: FractionalOffset.topCenter,
                  child: new PhysicalModel(
                    clipBehavior: Clip.antiAlias,
                    color: _kStoryBackgroundColor,
                    elevation: storyElevationWithTabs,
                    borderRadius: new BorderRadius.vertical(
                      bottom: new Radius.circular(
                        lerpDouble(
                          _kUnfocusedCornerRadius,
                          _kFocusedCornerRadius,
                          focusProgress,
                        )!,
                      ),
                    ),
                    child: _getStoryContents(context, story),
                  ),
                ),
              ),
            ],
          );
  }

  /// We want to round both story bar corners if the cluster is in panel mode.
  /// If the cluster is in tab mode we want to round the top left corner if the
  /// story is the first tab and the top right corner if the story is the last
  /// tab.
  BorderRadius _getStoryBarBorderRadius(Story story) => new BorderRadius.only(
        topLeft: (storyCluster.displayMode != DisplayMode.tabs ||
                storyCluster.stories[0].id == story.id)
            ? new Radius.circular(
                lerpDouble(
                  _kUnfocusedCornerRadius,
                  _kFocusedCornerRadius,
                  focusProgress,
                )!,
              )
            : Radius.zero,
        topRight: (storyCluster.displayMode != DisplayMode.tabs ||
                storyCluster.stories[storyCluster.stories.length - 1].id ==
                    story.id)
            ? new Radius.circular(
                lerpDouble(
                  _kUnfocusedCornerRadius,
                  _kFocusedCornerRadius,
                  focusProgress,
                )!,
              )
            : Radius.zero,
      );

  /// The scaled and clipped story.  When full size, the story will
  /// no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context, Story story) => new FittedBox(
        fit: BoxFit.cover,
        alignment: FractionalOffset.topCenter,
        child: new StoryFullSizeSimulatedSizedBox(
          displayMode: storyCluster.displayMode,
          panel: story.panel,
          storyBarMaximizedHeight: SizeModel.kStoryBarMaximizedHeight,
          child: story.widget!,
        ),
      );

  /// Sets the fractionalLeftPadding [0] and fractionalRightPadding [1] for
  /// the [story].  If [growFocused] is true, the focused story is given double
  /// the width of the other stories.
  void _setStoryBarPadding({
    required Story story,
    required double width,
    bool growFocused = _kGrowFocusedTab,
  }) {
    if (storyCluster.displayMode == DisplayMode.panels) {
      story.simulatedPaddingModel.update(
        fractionalLeftPadding: 0.0,
        fractionalRightPadding: 0.0,
      );
      return;
    }
    int storyBarGaps = storyCluster.stories.length - 1;
    int spaces = _kGrowFocusedTab
        ? storyCluster.stories.length + 1
        : storyCluster.stories.length;
    double gapFractionalWidth = 4.0 / width;
    double fractionalWidthPerSpace =
        (1.0 - (storyBarGaps * gapFractionalWidth)) / spaces;

    int index = storyCluster.stories.indexOf(story);
    double left = 0.0;
    for (int i = 0; i < storyCluster.stories.length; i++) {
      if (i == index) {
        break;
      }
      left += fractionalWidthPerSpace + gapFractionalWidth;
      if (growFocused &&
          storyCluster.stories[i].id == storyCluster.focusedStoryId) {
        left += fractionalWidthPerSpace;
      }
    }
    double fractionalWidth =
        growFocused && (story.id == storyCluster.focusedStoryId)
            ? 2.0 * fractionalWidthPerSpace
            : fractionalWidthPerSpace;
    double right = 1.0 - left - fractionalWidth;

    story.simulatedPaddingModel.update(
      fractionalLeftPadding: left,
      fractionalRightPadding: right,
    );
  }
}
