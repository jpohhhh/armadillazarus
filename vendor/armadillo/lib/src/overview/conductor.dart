// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/common.dart';
import 'package:armadillo/next.dart';
import 'package:armadillo/now.dart';
import 'package:armadillo/recent.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'conductor_model.dart';

/// When the recent list's scrollOffset exceeds this value we minimize Now.
const double _kNowMinimizationScrollOffsetThreshold = 120.0;

/// When the recent list's scrollOffset exceeds this value we hide quick
/// settings Now.
const double _kNowQuickSettingsHideScrollOffsetThreshold = 16.0;

/// Manages the position, size, and state of the story list, user context,
/// suggestion overlay, device extensions. interruption overlay, and quick
/// settings overlay.
class Conductor extends StatefulWidget {
  /// Constructor.
  const Conductor({Key? key}) : super(key: key);

  @override
  ConductorState createState() => new ConductorState();
}

/// Manages the state for [Conductor].
class ConductorState extends State<Conductor> {
  final ValueNotifier<double> _recentsScrollOffset =
      new ValueNotifier<double>(0.0);

  bool _ignoreNextScrollOffsetChange = false;
  double _pointerDownY = 0.0;

  /// Scroll offset affects the bottom padding of the user and text elements
  /// as well as the overall height of Now while maximized.
  double _lastRecentsScrollOffset = 0.0;

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<ConductorModel>(
        builder: (_, __, ConductorModel conductorModel) {
          conductorModel.nowBuilder
            ..onMinimize = () {
              PeekModel.of(context).nowMinimized = true;
              conductorModel.nextBuilder.hide();
            }
            ..onMaximize = () {
              PeekModel.of(context).nowMinimized = false;
              conductorModel.nextBuilder.hide();
            };

          return _buildParts(context, conductorModel);
        },
      );

  /// Note in particular the magic we're employing here to make the user
  /// state appear to be a part of the story list:
  /// By giving the story list bottom padding and clipping its bottom to the
  /// size of the final user state bar we have the user state appear to be
  /// a part of the story list and yet prevent the story list from painting
  /// behind it.
  Widget _buildParts(
    BuildContext context,
    ConductorModel conductorModel,
  ) =>
      new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          /// Idle Mode.
          conductorModel.idleModeBuilder.build(context),

          /// Story List.
          conductorModel.recentsBuilder.build(
            context,
            onScroll: (double scrollOffset) {
              _recentsScrollOffset.value = scrollOffset;

              if (_ignoreNextScrollOffsetChange) {
                _ignoreNextScrollOffsetChange = false;
                return;
              }

              double recentsScrollOffset =
                  scrollOffset + SizeModel.of(context).storyListTopPadding;
              if (recentsScrollOffset >
                      _kNowMinimizationScrollOffsetThreshold &&
                  _lastRecentsScrollOffset < recentsScrollOffset) {
                conductorModel.nowBuilder.minimize();
                QuickSettingsProgressModel.of(context).hide();
              } else if (recentsScrollOffset <
                      _kNowMinimizationScrollOffsetThreshold &&
                  _lastRecentsScrollOffset > recentsScrollOffset) {
                conductorModel.nowBuilder.maximize();
              }
              // When we're past the quick settings threshold and are
              // scrolling further, hide quick settings.
              if (recentsScrollOffset >
                      _kNowQuickSettingsHideScrollOffsetThreshold &&
                  _lastRecentsScrollOffset < recentsScrollOffset) {
                QuickSettingsProgressModel.of(context).hide();
              }
              _lastRecentsScrollOffset = recentsScrollOffset;

              conductorModel.nextBuilder.onRecentsScrollOffsetChanged(
                context,
                scrollOffset,
              );
            },
            onStoryClusterVerticalEdgeHover: goToOrigin,
          ),

          new Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (PointerDownEvent event) {
              _pointerDownY = event.position.dy;
            },
            onPointerUp: (PointerUpEvent event) {
              // When the user lifts their finger after overscrolling we may
              // want to snap suggestions open.
              // We will do so if the overscroll is significant or if the user
              // lifted after dragging a certain distance.
              if (conductorModel.recentsBuilder.isSignificantlyOverscrolled(
                  _pointerDownY - event.position.dy)) {
                conductorModel.nextBuilder.show();
              }
              QuickSettingsProgressModel.of(context).target = 0.0;
            },
          ),
          // Now.
          conductorModel.nowBuilder.build(
            context,
            onMinimizedTap: goToOrigin,
            onQuickSettingsMaximized: conductorModel.recentsBuilder.resetScroll,
            onBarVerticalDragUpdate:
                conductorModel.nextBuilder.onNowBarVerticalDragUpdate,
            onBarVerticalDragEnd:
                conductorModel.nextBuilder.onNowBarVerticalDragEnd,
            onMinimizedContextTapped: conductorModel.nextBuilder.show,
            recentsScrollOffset: _recentsScrollOffset,
          ),

          // Suggestions Overlay.
          conductorModel.nextBuilder.build(
            context,
            onMinimizeNow: _minimizeNow,
          ),
        ],
      );

  /// Call when a story cluster begins focusing.
  void onStoryClusterFocusStarted() {
    // Lock scrolling.
    ConductorModel.of(context).recentsBuilder.onStoryFocused();
    _minimizeNow();
  }

  /// Call when a story cluster finishes focusing.
  void onStoryClusterFocusCompleted(StoryCluster storyCluster) {
    // Tell the [StoryModel] the story is now in focus.  This will move the
    // [Story] to the front of the [StoryList].
    StoryModel.of(context).interactionStarted(storyCluster);

    // We need to set the scroll offset to 0.0 to ensure the story
    // bars don't become untouchable when fully focused:
    // If we're at a scroll offset other than zero, the RenderStoryListBody
    // might not be as big as it would need to be to fully cover the screen and
    // thus would have areas where its painting but not receiving hit testing.
    // Right now the RenderStoryListBody ensures that its at least the size of
    // the screen when we're focused but doesn't take into account the scroll
    // offset.  It seems weird to size the RenderStoryListBody based on the
    // scroll offset and it also seems weird to scroll to offset 0.0 from some
    // arbitrary scroll offset when we defocus so this solves both issues with
    // one stone.
    //
    // If we don't ignore the onScroll resulting from setting the scroll offset
    // to 0.0 we will inadvertently maximize now and peek the suggestion
    // overlay.
    _ignoreNextScrollOffsetChange = true;
    ConductorModel.of(context).recentsBuilder.resetScroll(jump: true);
    ConductorModel.of(context).recentsBuilder.onStoryFocused();
  }

  void _minimizeNow() {
    ConductorModel.of(context).nowBuilder.minimize();
    QuickSettingsProgressModel.of(context).hide();
    PeekModel.of(context).nowMinimized = true;
    ConductorModel.of(context).nextBuilder.hide();
  }

  /// Returns the state of the children to their initial values.
  /// This includes:
  /// 1) Unfocusing any focused stories.
  /// 2) Maximizing now.
  /// 3) Enabling scrolling of the story list.
  /// 4) Scrolling to the beginning of the story list.
  /// 5) Peeking the suggestion list.
  void goToOrigin() {
    // Unfocus all story clusters.
    StoryModel storyModel = StoryModel.of(context)..unfocusAll();

    // Unlock scrolling.
    ConductorModel.of(context).recentsBuilder.onStoryUnfocused();
    ConductorModel.of(context).recentsBuilder.resetScroll();
    ConductorModel.of(context).nowBuilder.maximize();
    storyModel
      ..interactionStopped()
      ..clearPlaceHolderStoryClusters();
  }

  /// Called to request the conductor focus on the cluster with [storyId].
  void requestStoryFocus(StoryId storyId, {bool jumpToFinish = true}) {
    onStoryClusterFocusStarted();
    StoryModel storyModel = StoryModel.of(context);
    StoryCluster? storyCluster = storyModel.storyClusterWithStory(storyId);

    // There should be one story cluster with a story with this id.  If
    // that's not true, bail out.
    if (storyCluster == null) {
      goToOrigin();
    } else {
      // Unfocus all story clusters.
      storyModel.unfocusAll();

      // Ensure the focused story is completely expanded.
      if (jumpToFinish) {
        storyCluster.focusModel.jump(1.0);
        storyCluster.storyClusterEntranceTransitionModel.jump(1.0);
      } else {
        storyCluster.focusModel.target = 1.0;
        storyCluster.storyClusterEntranceTransitionModel.target = 1.0;
      }

      // Ensure the focused story's story bar is full open.
      storyCluster.maximizeStoryBars(jumpToFinish: jumpToFinish);

      // Focus on the story cluster.
      onStoryClusterFocusCompleted(storyCluster);
    }

    ConductorModel.of(context).nextBuilder.resetSelection();
  }
}
