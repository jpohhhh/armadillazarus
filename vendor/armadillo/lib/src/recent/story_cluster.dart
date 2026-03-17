// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';

import 'armadillo_drag_target.dart';
import 'display_mode.dart';
import 'focus_model.dart';
import 'panel.dart';
import 'panel_drag_targets.dart';
import 'place_holder_story.dart';
import 'story.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_entrance_transition_model.dart';
import 'story_cluster_id.dart';
import 'story_cluster_panels_model.dart';
import 'story_cluster_stories_model.dart';
import 'story_cluster_widget.dart';
import 'story_list_layout.dart';
import 'story_panels.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Called when something related to [storyCluster] happens.
typedef OnStoryClusterEvent = void Function(StoryCluster storyCluster);

/// A data model representing a list of [Story]s.
class StoryCluster {
  /// The unique id of the cluster.
  final StoryClusterId id;

  /// The list of stories contained in the cluster.
  final List<Story> _stories;

  /// The key used for the cluster's [StoryClusterWidget]'s
  /// [PanelDragTargets].
  final GlobalKey clusterDragTargetsKey;

  /// The key used for the cluster's [StoryPanels].
  final GlobalKey panelsKey;

  /// The key used for the cluster's [StoryClusterDragFeedback].
  final GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey;

  /// The inline preview scale simulation is the scaling that occurs when the
  /// user drags a cluster over this cluster while in the timeline after the
  /// inline preview timeout occurs.
  final InlinePreviewScaleModel inlinePreviewScaleModel =
      new InlinePreviewScaleModel();

  /// The inline preview hint scale simulation is the scaling that occurs when
  /// the user drags a cluster over this cluster while in the timeline before
  /// the inline preview timeout occurs.
  final InlinePreviewHintScaleModel inlinePreviewHintScaleModel =
      new InlinePreviewHintScaleModel();

  final Set<VoidCallback> _storyListListeners;

  /// Called when details about how the stories are clustered changes.
  final VoidCallback? onStoryClusterChanged;

  /// The model handling the entrance transtion of the cluster.
  final StoryClusterEntranceTransitionModel storyClusterEntranceTransitionModel;

  /// The focus progress of the cluster.
  final FocusModel focusModel = new FocusModel();

  /// The title of a cluster is currently generated via
  /// [_getClusterTitle] whenever the list of stories in this cluster changes.
  /// [_getClusterTitle] currently just concatenates the titles of the stories
  /// within the cluster.
  String title;

  /// The key used for the cluster's [StoryClusterWidget]'s
  /// [ArmadilloLongPressDraggable].
  GlobalKey clusterDraggableKey;

  /// The layout this cluster should use to place and size itself.
  StoryLayout? storyLayout;

  DateTime _lastInteraction;
  Duration _cumulativeInteractionDuration;
  DisplayMode _displayMode;
  StoryId _focusedStoryId;
  late StoryClusterStoriesModel _storiesModel;
  late StoryClusterPanelsModel _panelsModel;

  /// Constructor.
  StoryCluster({
    StoryClusterId? id,
    GlobalKey? clusterDraggableKey,
    required List<Story> stories,
    this.storyLayout,
    this.onStoryClusterChanged,
    StoryClusterEntranceTransitionModel? storyClusterEntranceTransitionModel,
  })  : assert(stories.length > 0),
        _stories = stories,
        title = _getClusterTitle(stories),
        _lastInteraction = _getClusterLastInteraction(stories),
        _cumulativeInteractionDuration =
            _getClusterCumulativeInteractionDuration(stories),
        id = id ?? new StoryClusterId(),
        clusterDraggableKey = clusterDraggableKey ??
            new GlobalKey(debugLabel: 'clusterDraggableKey'),
        clusterDragTargetsKey =
            new GlobalKey(debugLabel: 'clusterDragTargetsKey'),
        panelsKey = new GlobalKey(debugLabel: 'panelsKey'),
        dragFeedbackKey = new GlobalKey<StoryClusterDragFeedbackState>(
            debugLabel: 'dragFeedbackKey'),
        _displayMode = DisplayMode.panels,
        _storyListListeners = new Set<VoidCallback>(),
        _focusedStoryId = stories[0].id,
        storyClusterEntranceTransitionModel =
            storyClusterEntranceTransitionModel ??
                new StoryClusterEntranceTransitionModel() {
    _storiesModel = new StoryClusterStoriesModel(this);
    addStoryListListener(_storiesModel.notifyListeners);
    _panelsModel = new StoryClusterPanelsModel(this);
    if (onStoryClusterChanged != null) {
      _storiesModel.addListener(onStoryClusterChanged!);
      _panelsModel.addListener(onStoryClusterChanged!);
    }
  }

  /// Creates a [StoryCluster] from [story].
  factory StoryCluster.fromStory(
    Story story,
    VoidCallback onStoryClusterChanged,
  ) {
    story
      ..panel = new Panel()
      ..positionedKey = new GlobalKey(debugLabel: '${story.id} positionedKey');
    return new StoryCluster(
      id: story.clusterId,
      clusterDraggableKey: story.clusterDraggableKey,
      stories: <Story>[story],
      onStoryClusterChanged: onStoryClusterChanged,
    );
  }

  /// Creates a StoryCluster from a json object returned by [toJson].
  factory StoryCluster.fromJson(Map<String, dynamic> clusterData) {
    StoryCluster storyCluster = new StoryCluster(
      stories: clusterData['stories']
          .map((Map<String, dynamic> json) => new Story.fromJson(json))
          .toList(),
    )
      ..displayMode = clusterData['display_mode'] == 'tabs'
          ? DisplayMode.tabs
          : DisplayMode.panels
      ..focusedStoryId = new StoryId(clusterData['focused_story_id']);
    return storyCluster;
  }

  /// Wraps [child] with the [Model]s corresponding to this [StoryCluster].
  Widget wrapWithModels({required Widget child}) =>
      new ScopedModel<StoryClusterStoriesModel>(
        model: _storiesModel,
        child: new ScopedModel<StoryClusterPanelsModel>(
          model: _panelsModel,
          child: child,
        ),
      );

  /// The list of stories in this cluster including both 'real' stories and
  /// place holder stories.
  List<Story> get stories => new UnmodifiableListView<Story>(_stories);

  /// The list of 'real' stories in this cluster.
  List<Story> get realStories => new UnmodifiableListView<Story>(
        _stories.where((Story story) => !story.isPlaceHolder),
      );

  /// The list of place holder stories in this cluster.
  List<PlaceHolderStory> get previewStories =>
      new List<PlaceHolderStory>.unmodifiable(
        _stories.whereType<PlaceHolderStory>(),
      );

  /// [listener] will be called whenever the list of stories changes.
  void addStoryListListener(VoidCallback listener) {
    _storyListListeners.add(listener);
  }

  /// [listener] will no longer be called whenever the list of stories changes.
  void removeStoryListListener(VoidCallback listener) {
    _storyListListeners.remove(listener);
  }

  void _notifyStoryListListeners() {
    title = _getClusterTitle(realStories);
    _lastInteraction = _getClusterLastInteraction(stories);
    _cumulativeInteractionDuration = _getClusterCumulativeInteractionDuration(
      stories,
    );
    for (VoidCallback listener in _storyListListeners) {
      listener();
    }
    _panelsModel.notifyListeners();
  }

  /// Sets the last interaction time for the cluster.  Used for ordering
  /// clusters in the story list.
  set lastInteraction(DateTime lastInteraction) {
    _lastInteraction = lastInteraction;
    for (Story story in _stories) {
      story.lastInteraction = lastInteraction;
    }
  }

  /// Gets the last interaction time for the cluster.
  DateTime get lastInteraction => _lastInteraction;

  /// Sets the cumulative interaction time this cluster has had.  Used for
  /// ordering laying out clusters in the story list.
  set cumulativeInteractionDuration(Duration cumulativeInteractionDuration) {
    _cumulativeInteractionDuration = cumulativeInteractionDuration;
    for (Story story in _stories) {
      story.cumulativeInteractionDuration = cumulativeInteractionDuration;
    }
  }

  /// Gets the cumulative interaction time this cluster has had.
  Duration get cumulativeInteractionDuration => _cumulativeInteractionDuration;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is StoryCluster && other.id == id;

  @override
  String toString() {
    StringBuffer string =
        new StringBuffer('StoryCluster( id: $id, title: $title,\n');
    for (Story story in _stories) {
      string.write('\n   story: $story');
    }
    string.write(' )');
    return string.toString();
  }

  /// The current [DisplayMode] of this cluster.
  DisplayMode get displayMode => _displayMode;

  /// Switches the [DisplayMode] to [displayMode].
  set displayMode(DisplayMode displayMode) {
    if (_displayMode != displayMode) {
      _displayMode = displayMode;
      _panelsModel.notifyListeners();
    }
  }

  /// Removes any preview stories from [stories]
  Map<StoryId, PlaceHolderStory> removePreviews() {
    Map<StoryId, PlaceHolderStory> storiesRemoved =
        <StoryId, PlaceHolderStory>{};
    for (Story story in _stories.toList()) {
      if (story is PlaceHolderStory) {
        absorb(story);
        storiesRemoved[story.associatedStoryId] = story;
      }
    }

    return storiesRemoved;
  }

  /// Returns the [Panel]s of the [stories].
  Iterable<Panel> get panels => _stories.map((Story story) => story.panel);

  /// Resizes the [Panel]s of the [stories] to have columns with equal widths
  /// and rows of equal heights.
  void normalizeSizes() {
    Set<double> currentLeftsSet = new Set<double>();
    Set<double> currentTopsSet = new Set<double>();
    for (Panel panel in panels) {
      currentLeftsSet.add(panel.left);
      currentTopsSet.add(panel.top);
    }

    List<double> currentSortedLefts = new List<double>.from(currentLeftsSet)
      ..sort();

    List<double> currentSortedTops = new List<double>.from(currentTopsSet)
      ..sort();

    Map<double, double> leftMap = <double, double>{1.0: 1.0};
    double left = 0.0;
    for (int i = 0; i < currentSortedLefts.length; i++) {
      leftMap[currentSortedLefts[i]] = left;
      left = toGridValue(left + getSpanSpan(1.0, i, currentSortedLefts.length));
    }

    Map<double, double> topMap = <double, double>{1.0: 1.0};
    double top = 0.0;
    for (int i = 0; i < currentSortedTops.length; i++) {
      topMap[currentSortedTops[i]] = top;
      top = toGridValue(top + getSpanSpan(1.0, i, currentSortedTops.length));
    }

    for (Panel panel in panels.toList()) {
      assert(() {
        bool hadErrors = false;
        if (leftMap[panel.left] == null) {
          print('leftMap doesn\'t contain left ${panel.left}: ${leftMap.keys}');
          hadErrors = true;
        }
        if (topMap[panel.top] == null) {
          print('topMap doesn\'t contain top ${panel.top}: ${topMap.keys}');
          hadErrors = true;
        }
        if (leftMap[panel.right] == null) {
          print(
              'leftMap doesn\'t contain right ${panel.right}: ${leftMap.keys}');
          hadErrors = true;
        }
        if (topMap[panel.bottom] == null) {
          print(
              'topMap doesn\'t contain bottom ${panel.bottom}: ${topMap.keys}');
          hadErrors = true;
        }
        if (hadErrors) {
          for (Panel panel in panels) {
            print(' |--> $panel');
          }
        }
        return !hadErrors;
      }());
      replace(
        panel: panel,
        withPanel: new Panel.fromLTRB(
          leftMap[panel.left]!,
          topMap[panel.top]!,
          leftMap[panel.right]!,
          topMap[panel.bottom]!,
        ),
      );
    }
    _panelsModel.notifyListeners();
  }

  /// Adds the [story] to [stories] with a [Panel] of [withPanel].
  void add({required Story story, required Panel withPanel, int? atIndex}) {
    story.panel = withPanel;
    if (atIndex == null) {
      _stories.add(story);
    } else {
      _stories.insert(atIndex, story);
    }
    _notifyStoryListListeners();
  }

  /// Replaces the [Story.panel] of the story with [panel] with [withPanel]/
  void replace({required Panel panel, required Panel withPanel}) {
    _stories.where((Story story) => story.panel == panel).single.panel =
        withPanel;
    _panelsModel.notifyListeners();
  }

  /// Replaces the [Story.panel] of the story with [storyId] with [withPanel]/
  void replaceStoryPanel({required StoryId storyId, required Panel withPanel}) {
    _stories.where((Story story) => story.id == storyId).single.panel =
        withPanel;
    _panelsModel.notifyListeners();
  }

  /// Replaces the stories in this cluster with [replacementStories].
  void replaceStories(List<Story> replacementStories) {
    _stories
      ..clear()
      ..addAll(replacementStories);
    _notifyStoryListListeners();
  }

  /// true if this cluster has become a placeholder via [becomePlaceholder].
  bool get isPlaceholder => stories.length == 1 && stories.first.isPlaceHolder;

  /// Converts this cluster into a placeholder by replacing all its stories
  /// with a single place holder story.
  void becomePlaceholder() {
    _stories
      ..clear()
      ..add(new PlaceHolderStory(
          associatedStoryId: const StoryId('placeholder')));
    _notifyStoryListListeners();
  }

  /// Removes [story] from this cluster.  Stories adjacent to [story] in the
  /// cluster will absorb the area left behind by [story]'s [Story.panel].
  void absorb(Story story) {
    List<Story> stories = new List<Story>.from(_stories);
    // We can't absorb the story if it's the only story.
    if (stories.length <= 1) {
      return;
    }
    stories
      ..remove(story)
      ..sort(
        (Story a, Story b) => a.panel.sizeFactor > b.panel.sizeFactor
            ? 1
            : a.panel.sizeFactor < b.panel.sizeFactor
                ? -1
                : 0,
      );

    Panel remainingAreaToAbsorb = story.panel;
    double remainingSize;
    Story absorbingStory;
    do {
      remainingSize = remainingAreaToAbsorb.sizeFactor;
      absorbingStory = stories
          .where((Story story) => story.panel.canAbsorb(remainingAreaToAbsorb))
          .first;
      absorbingStory.panel.absorb(remainingAreaToAbsorb,
          (Panel absorbed, Panel remainder) {
        absorbingStory.panel = absorbed;
        remainingAreaToAbsorb = remainder;
      });
    } while (remainingAreaToAbsorb.sizeFactor < remainingSize &&
        remainingAreaToAbsorb.sizeFactor > 0.0);
    assert(remainingAreaToAbsorb.sizeFactor == 0.0);

    int absorbedStoryIndex = _stories.indexOf(story);
    _stories.remove(story);
    normalizeSizes();

    // If we've just removed the focused story, switch focus to a tab adjacent
    // story.
    if (focusedStoryId == story.id) {
      focusedStoryId = _stories[absorbedStoryIndex >= _stories.length
              ? _stories.length - 1
              : absorbedStoryIndex]
          .id;
    }

    _notifyStoryListListeners();
  }

  /// Sets the focused story for this cluster.
  set focusedStoryId(StoryId storyId) {
    if (storyId != _focusedStoryId) {
      _focusedStoryId = storyId;
      _panelsModel.notifyListeners();
    }
  }

  /// The id of the currently focused story.
  StoryId get focusedStoryId => _focusedStoryId;

  /// Unfocuses the story cluster.
  void unFocus() {
    focusModel.target = 0.0;
    minimizeStoryBars();
  }

  /// Maximizes the story bars for all the stories within the cluster.
  /// See [Story.maximizeStoryBar].
  void maximizeStoryBars({bool jumpToFinish = false}) {
    for (Story story in stories) {
      story.maximizeStoryBar(jumpToFinish: jumpToFinish);
    }
  }

  /// Minimizes the story bars for all the stories within the cluster.
  /// See [Story.minimizeStoryBar].
  void minimizeStoryBars() {
    for (Story story in stories) {
      story.minimizeStoryBar();
    }
  }

  /// Hides the story bars for all the stories within the cluster.
  /// See [Story.hideStoryBar].
  void hideStoryBars() {
    for (Story story in stories) {
      story.hideStoryBar();
    }
  }

  /// Shows the story bars for all the stories within the cluster.
  /// See [Story.showStoryBar].
  void showStoryBars() {
    for (Story story in stories) {
      story.showStoryBar();
    }
  }

  /// Moves the [storiesToMove] from their current location in the story list
  /// to [targetIndex].
  void moveStoriesToIndex(List<Story> storiesToMove, int targetIndex) {
    List<Story> removedStories = <Story>[];
    for (Story storyToMove in storiesToMove) {
      Story story =
          stories.where((Story story) => story.id == storyToMove.id).single;
      _stories.remove(story);
      removedStories.add(story);
    }
    for (Story removedStory in removedStories.reversed) {
      _stories.insert(targetIndex, removedStory);
    }
    _notifyStoryListListeners();
  }

  /// Moves the [storiesToMove] from their current location in the story list
  /// to [targetIndex].  This differs from [moveStoriesToIndex] in that only
  /// [previewStories] are moved.
  void movePlaceholderStoriesToIndex(
    List<Story> storiesToMove,
    int targetIndex,
  ) {
    List<Story> removedStories = <Story>[];
    for (Story storyToMove in storiesToMove) {
      Story story = previewStories
          .where((PlaceHolderStory story) =>
              story.associatedStoryId == storyToMove.id)
          .single;
      _stories.remove(story);
      removedStories.add(story);
    }
    for (Story removedStory in removedStories.reversed) {
      _stories.insert(targetIndex, removedStory);
    }
    _notifyStoryListListeners();
  }

  /// Mirrors the order of [stories] to match the given [storiesToMirror].
  /// Note in this case the stories in [storiesToMirror] are expected to have
  /// the opposite 'realness' as those in [stories] (ie. A placeholder story in
  /// [storiesToMirror] corresponds to a non-placeholder story in [stories] and
  /// vice versa).
  void mirrorStoryOrder(List<Story> storiesToMirror) {
    for (int i = 0; i < storiesToMirror.length; i++) {
      if (storiesToMirror[i].isPlaceHolder) {
        PlaceHolderStory placeHolderMirror =
            storiesToMirror[i] as PlaceHolderStory;
        Story story = stories
            .where((Story story) =>
                story.id == placeHolderMirror.associatedStoryId)
            .single;
        _stories
          ..remove(story)
          ..insert(i, story);
      } else {
        Story realMirror = storiesToMirror[i];
        Story story = previewStories
            .where((PlaceHolderStory story) =>
                story.associatedStoryId == realMirror.id)
            .single;
        _stories
          ..remove(story)
          ..insert(i, story);
      }
    }
  }

  /// Returns the [Story] in this cluster with an id of [storyId].  Returns
  /// null if that story is not within this cluster.
  Story? getStory(String storyId) {
    Iterable<Story> storiesWithId =
        realStories.where((Story story) => story.id.value == storyId);
    if (storiesWithId.isEmpty) {
      return null;
    }
    return storiesWithId.first;
  }

  /// Returns an object represeting the [StoryCluster] suitable for conversion
  /// into JSON.
  Map<String, dynamic> toJson() {
    Map<String, dynamic> clusterData = <String, dynamic>{};
    clusterData['stories'] = stories.toList();
    clusterData['display_mode'] =
        displayMode == DisplayMode.tabs ? 'tabs' : 'panels';
    clusterData['focused_story_id'] = focusedStoryId.value;

    return clusterData;
  }

  /// Updates this story cluster to have the info as [other].
  void update(StoryCluster other) {
    /// 1. Replace stories.
    _stories
      ..clear()
      ..addAll(other.stories);

    /// 2. Set display mode.
    displayMode = other.displayMode;

    /// 3. Update focused story id.
    focusedStoryId = other.focusedStoryId;

    _notifyStoryListListeners();
  }

  static String _getClusterTitle(List<Story> stories) {
    StringBuffer title = new StringBuffer('');
    for (Story story in stories.where((Story story) => !story.isPlaceHolder)) {
      if (title.isNotEmpty) {
        title.write(', ');
      }
      title.write(story.title);
    }
    return title.toString();
  }

  static DateTime _getClusterLastInteraction(List<Story> stories) {
    DateTime latestTime = new DateTime(1970);
    for (Story story in stories.where((Story story) => !story.isPlaceHolder)) {
      if (latestTime.isBefore(story.lastInteraction)) {
        latestTime = story.lastInteraction;
      }
    }
    return latestTime;
  }

  static Duration _getClusterCumulativeInteractionDuration(
      List<Story> stories) {
    Duration largestDuration = const Duration();
    for (Story story in stories.where((Story story) => !story.isPlaceHolder)) {
      if (largestDuration < story.cumulativeInteractionDuration) {
        largestDuration = story.cumulativeInteractionDuration;
      }
    }
    return largestDuration;
  }
}

const RK4SpringDescription _kInlinePreviewSimulationDesc =
    const RK4SpringDescription(tension: 900.0, friction: 50.0);

/// The inline preview scale simulation is the scaling that occurs when the
/// user drags a cluster over this cluster while in the timeline after the
/// inline preview timeout occurs.
class InlinePreviewScaleModel extends SpringModel {
  /// Constructor.
  InlinePreviewScaleModel()
      : super(springDescription: _kInlinePreviewSimulationDesc);
}

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// The inline preview hint scale simulation is the scaling that occurs when
/// the user drags a cluster over this cluster while in the timeline before
/// the inline preview timeout occurs.
class InlinePreviewHintScaleModel extends SpringModel {
  /// Constructor.
  InlinePreviewHintScaleModel() : super(springDescription: _kSimulationDesc);
}
