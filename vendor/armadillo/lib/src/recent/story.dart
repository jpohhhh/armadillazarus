// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import 'panel.dart';
import 'simulated_fractional.dart';
import 'simulated_fractionally_sized_box.dart';
import 'simulated_padding.dart';
import 'story_bar.dart';
import 'story_cluster_id.dart';
import 'story_list.dart';

/// The ID of a Story as a [ValueKey].
class StoryId extends ValueKey<String> {
  /// Constructs a StoryId by passing [value] to [ValueKey]'s constructor.
  const StoryId(String value) : super(value);
}

/// A builder that is called for different values of [opacity].
typedef OpacityBuilder = Widget Function(BuildContext context, double opacity);

/// The representation of a Story.  A Story's contents are display as a [Widget]
/// provided by [widget] while the size of a story in the [StoryList] is
/// determined by [lastInteraction] and [cumulativeInteractionDuration].
class Story {
  /// The Story's ID.
  final StoryId id;

  /// The [Widget] representation of the story.
  final Widget? widget;

  /// The icons indicating the source of the story.
  final List<OpacityBuilder> icons;

  /// The title of the story.
  final String title;

  /// The story's theme color.  The Story's bar and background are set to this
  /// color.
  final Color themeColor;

  /// The ID of the cluster this story will form if it is removed from a
  /// different cluster.
  final StoryClusterId clusterId;

  /// Handles the transition when the story bar minimizes and maximizes.
  final StoryBarHeightModel _storyBarHeightModel = new StoryBarHeightModel();

  /// Handles the transition when the story becomes focused.
  final StoryBarFocusModel _storyBarFocusModel = new StoryBarFocusModel();

  /// The state of the padding being applied to the story's story bar.
  final SimulatedPaddingModel simulatedPaddingModel;

  /// The key of draggable portion of the widget represeting this story.
  final GlobalKey clusterDraggableKey;

  /// The state of the container that sizes the story's widget in tab mode.
  final SimulatedFractionallySizedBoxModel simulatedFractionallySizedBoxModel;

  /// Called when the cluster index of this story changes.
  final ValueChanged<int>? onClusterIndexChanged;

  /// A timestamp of the last time this story was interacted with.  This is used
  /// for sorting the story list and for determining the size of the story's
  /// widget in the story list.
  DateTime lastInteraction;

  /// The culmulative interaction duration the user has had with is story.  This
  /// is used for determining the size of the story's widget in the story list.
  Duration cumulativeInteractionDuration;

  /// The key of the container that position's the story's widget within its
  /// cluster.
  GlobalKey<SimulatedFractionalState> positionedKey;

  /// The location of the story's widget within its cluster.
  Panel panel;

  /// The index of the cluster this story is in.
  int _clusterIndex;

  /// Constructor.
  Story({
    StoryId? id,
    this.widget,
    this.title = '',
    this.icons = const <OpacityBuilder>[],
    DateTime? lastInteraction,
    this.cumulativeInteractionDuration = Duration.zero,
    this.themeColor = Colors.black,
    this.onClusterIndexChanged,
    StoryClusterId? clusterId,
    SimulatedPaddingModel? simulatedPaddingState,
    GlobalKey? clusterDraggableKey,
    GlobalKey<SimulatedFractionalState>? positionedKey,
    SimulatedFractionallySizedBoxModel? simulatedFractionallySizedBoxState,
    Panel? panel,
    int? clusterIndex,
    StoryBarHeightModel? storyBarHeightModel,
    StoryBarFocusModel? storyBarFocusModel,
  })  : id = id ??
            new StoryId(new DateTime.now().microsecondsSinceEpoch.toString()),
        clusterId = clusterId ?? new StoryClusterId(),
        simulatedPaddingModel =
            simulatedPaddingState ?? new SimulatedPaddingModel(),
        clusterDraggableKey = clusterDraggableKey ??
            new GlobalKey(debugLabel: '$id clusterDraggableKey'),
        positionedKey =
            positionedKey ?? new GlobalKey(debugLabel: '$id positionedKey'),
        simulatedFractionallySizedBoxModel =
            simulatedFractionallySizedBoxState ??
                new SimulatedFractionallySizedBoxModel(),
        panel = panel ?? new Panel(),
        lastInteraction = lastInteraction ?? new DateTime.now(),
        _clusterIndex = clusterIndex ?? 0 {
    if (storyBarHeightModel != null) {
      _storyBarHeightModel.jump(storyBarHeightModel.value);
    }
    if (storyBarFocusModel != null) {
      _storyBarFocusModel.jump(storyBarFocusModel.value);
    }
  }

  /// Creates a Story from a json object returned by [toJson].
  factory Story.fromJson(Map<String, dynamic> storyData) {
    Story story = new Story(id: new StoryId(storyData['id']))
      ..panel = new Panel.fromJson(storyData['panel'])
      .._clusterIndex = storyData['cluster_index'];
    return story;
  }

  /// Wraps [child] with the [Model]s corresponding to this [Story].
  Widget wrapWithModels({required Widget child}) =>
      new ScopedModel<StoryBarHeightModel>(
        model: _storyBarHeightModel,
        child: new ScopedModel<StoryBarFocusModel>(
          model: _storyBarFocusModel,
          child: child,
        ),
      );

  /// Returns true if the [Story] has no content and should just take up empty
  /// space.
  bool get isPlaceHolder => false;

  /// Maximizes the story's story bar.
  void maximizeStoryBar({bool jumpToFinish = false}) {
    _storyBarHeightModel.maximize(jumpToFinish: jumpToFinish);
    _storyBarFocusModel.maximize();
  }

  /// Minimizes the story's story bar.
  void minimizeStoryBar() {
    _storyBarHeightModel.minimize();
    _storyBarFocusModel.minimize();
  }

  /// Hides the story's story bar.
  void hideStoryBar() => _storyBarHeightModel.hide();

  /// Shows the story's story bar.
  void showStoryBar() => _storyBarHeightModel.show();

  /// Sets the story bar into focus mode if true.
  set storyBarFocus(bool storyBarFocus) {
    _storyBarFocusModel.focus = storyBarFocus;
  }

  /// Sets the cluster index of this story.
  set clusterIndex(int clusterIndex) {
    if (_clusterIndex != clusterIndex) {
      _clusterIndex = clusterIndex;
      onClusterIndexChanged?.call(_clusterIndex);
    }
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Story && other.id == id;

  @override
  String toString() => 'Story( id: $id, title: $title, panel: $panel )';

  /// Creates a new story with this story's values and [other]'s panel and
  /// cluster index.
  Story copyWithPanelAndClusterIndex(Story other) => new Story(
        id: id,
        widget: widget,
        title: title,
        icons: icons,
        lastInteraction: lastInteraction,
        cumulativeInteractionDuration: cumulativeInteractionDuration,
        themeColor: themeColor,
        onClusterIndexChanged: onClusterIndexChanged,
        clusterId: clusterId,
        simulatedPaddingState: simulatedPaddingModel,
        clusterDraggableKey: clusterDraggableKey,
        positionedKey: positionedKey,
        simulatedFractionallySizedBoxState: simulatedFractionallySizedBoxModel,
        panel: other.panel,
        clusterIndex: other._clusterIndex,
        storyBarFocusModel: _storyBarFocusModel,
        storyBarHeightModel: _storyBarHeightModel,
      );

  /// Returns an object represeting the [Story] suitable for conversion
  /// into JSON.
  Map<String, dynamic> toJson() {
    Map<String, dynamic> storyData = <String, dynamic>{};
    storyData['id'] = id.value;
    storyData['panel'] = panel;
    storyData['cluster_index'] = _clusterIndex;
    return storyData;
  }
}
