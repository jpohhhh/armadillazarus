// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'display_mode.dart';
import 'panel.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_id.dart';
import 'story_list_layout.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// A simple story model that gets its stories from calls
/// [onStoryClustersChanged] and  reorders them with user interaction.
class StoryModel extends Model {
  /// Called when the currently focused [StoryCluster] changes.
  final void Function(StoryCluster?)? onFocusChanged;

  /// Called when a [StoryCluster] should be deleted.
  final ValueChanged<StoryClusterId>? onDeleteStoryCluster;

  /// Called when a [StoryCluster] was added to the model's list.
  final ValueChanged<StoryCluster>? onStoryClusterAdded;

  /// Called when a [StoryCluster] was removed from the model's list.
  final ValueChanged<StoryCluster>? onStoryClusterRemoved;

  /// The most recent list of story clusters received from
  /// [onStoryClustersChanged].
  /// NOTE: While we may sort this list we should not add to or remove from it.
  /// Call [onStoryClusterAdded] and [onStoryClusterRemoved] to do so.
  /// This list is *NOT* the source of truth of the list of story clusters.
  List<StoryCluster> _storyClusters = <StoryCluster>[];
  Size _lastLayoutSize = Size.zero;
  double _listHeight = 0.0;

  /// Constructor.
  StoryModel({
    this.onFocusChanged,
    this.onDeleteStoryCluster,
    this.onStoryClusterAdded,
    this.onStoryClusterRemoved,
  });

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static StoryModel of(BuildContext context, {bool rebuildOnChange = false}) =>
      new ModelFinder<StoryModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  /// The current height of the story list.
  double get listHeight => _listHeight;

  /// Called to set a new list of [storyClusters].
  void onStoryClustersChanged(List<StoryCluster> storyClusters) {
    _storyClusters = storyClusters.toList();
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    // Update indicies
    for (int i = 0; i < _storyClusters.length; i++) {
      StoryCluster storyCluster = _storyClusters[i];
      for (Story story in storyCluster.stories) {
        story.clusterIndex = i;
      }
    }

    super.notifyListeners();
  }

  /// An unmodifiable list of all storyClusters.
  List<StoryCluster> get storyClusters =>
      new UnmodifiableListView<StoryCluster>(_storyClusters);

  /// An unmodifiable list of all stories.
  List<Story> get stories => new UnmodifiableListView<Story>(
        _storyClusters.expand(
          (StoryCluster storyCluster) => storyCluster.stories,
        ),
      );

  /// Returns true if all story clusters are unfocused.
  bool get allUnfocused => _storyClusters.every(
      (StoryCluster storyCluster) => storyCluster.focusModel.value == 0.0);

  /// Unfocuses all the story clusters.
  void unfocusAll() {
    for (StoryCluster storyCluster in _storyClusters) {
      storyCluster.unFocus();
    }
  }

  /// Iterates through the story clusters creating widgets with the given
  /// builder.
  List<Widget> toWidgets(Widget toWidget(StoryCluster storyCluster)) {
    return new List<Widget>.generate(
      _storyClusters.length,
      (int index) => toWidget(_storyClusters[index]),
    );
  }

  /// Returns the story cluster with the given id or null if no clusters
  /// have the id.
  StoryCluster? storyClusterWithId(StoryClusterId id) {
    Iterable<StoryCluster> storyClustersWithId = _storyClusters.where(
      (StoryCluster storyCluster) => storyCluster.id == id,
    );
    if (storyClustersWithId.isEmpty) {
      return null;
    }
    assert(storyClustersWithId.length == 1);
    return storyClustersWithId.first;
  }

  /// Returns the story cluster with the given story or null if no clusters
  /// contain the story.
  StoryCluster? storyClusterWithStory(StoryId storyId) {
    Iterable<StoryCluster> storyClustersWithStory =
        _storyClusters.where((StoryCluster storyCluster) {
      bool result = false;
      for (Story story in storyCluster.stories) {
        if (story.id == storyId) {
          result = true;
        }
      }
      return result;
    });
    if (storyClustersWithStory.isEmpty) {
      return null;
    }
    assert(storyClustersWithStory.length == 1);
    return storyClustersWithStory.first;
  }

  /// Gets the max focus progress of all the clusters.
  double get maxFocusProgress => _storyClusters.fold(
        0.0,
        (double max, StoryCluster storyCluster) => math.max(
          max,
          storyCluster.focusModel.value,
        ),
      );

  /// Updates the [size] used to layout the stories.
  void updateLayouts(Size size) {
    if (size.width == 0.0 || size.height == 0.0) {
      return;
    }
    _lastLayoutSize = size;

    // Sort recently interacted with stories to the start of the list.
    _storyClusters.sort((StoryCluster a, StoryCluster b) =>
        b.lastInteraction.millisecondsSinceEpoch -
        a.lastInteraction.millisecondsSinceEpoch);

    List<StoryLayout> storyLayout = new StoryListLayout(size: size).layout(
      storyClustersToLayout: new UnmodifiableListView<StoryCluster>(
        _storyClusters,
      ),
      currentTime: new DateTime.now(),
    );

    double listHeight = 0.0;
    for (int i = 0; i < storyLayout.length; i++) {
      _storyClusters[i].storyLayout = storyLayout[i];
      listHeight = math.max(listHeight, -storyLayout[i].offset.dy);
    }
    _listHeight = listHeight;

    /// We delay each story a bit more so we have a staggered entrance
    /// transition.  We also delay all stories by a set amount dependent on the
    /// number of clusters that haven't loaded in yet.  This should reduce jank
    /// while those clusters load for the first time.
    int unenteredClusters = _storyClusters
        .where(
          (StoryCluster storyCluster) =>
              storyCluster.storyClusterEntranceTransitionModel.value == 0.0,
        )
        .length;

    int delayMultiple = 0;
    for (StoryCluster storyCluster in _storyClusters) {
      if (storyCluster.storyClusterEntranceTransitionModel.value == 0.0) {
        storyCluster.storyClusterEntranceTransitionModel.reset(
          delay:
              (0.5 * math.min(6, unenteredClusters)) + (0.25 * delayMultiple),
          completed: false,
        );
        delayMultiple++;
      }
    }
  }

  /// Updates the [Story.lastInteraction] of [storyCluster] to be [DateTime.now].
  /// This method is to be called whenever a [Story]'s [Story.builder] [Widget]
  /// comes into focus.
  void interactionStarted(StoryCluster storyCluster) {
    storyCluster.lastInteraction = new DateTime.now();
    updateLayouts(_lastLayoutSize);
    notifyListeners();
    onFocusChanged?.call(storyCluster);
  }

  /// Indicates the currently focused story cluster has been defocused.
  void interactionStopped() {
    notifyListeners();
    onFocusChanged?.call(null);
  }

  /// Randomizes story interaction times within the story cluster.
  void randomizeStoryTimes() {
    math.Random random = new math.Random();
    DateTime storyInteractionTime = new DateTime.now();
    for (StoryCluster storyCluster in _storyClusters) {
      storyInteractionTime = storyInteractionTime.subtract(
          new Duration(minutes: math.max(0, random.nextInt(100) - 70)));
      Duration interaction = new Duration(minutes: random.nextInt(60));
      storyCluster
        ..lastInteraction = storyInteractionTime
        ..cumulativeInteractionDuration = interaction;
      storyInteractionTime = storyInteractionTime.subtract(interaction);
    }
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Adds [source]'s stories to [target]'s stories and removes [source] from
  /// the list of story clusters.
  void combine({required StoryCluster source, required StoryCluster target}) {
    // Update grid locations.
    for (int i = 0; i < source.stories.length; i++) {
      Story sourceStory = source.stories[i];
      Story largestStory = _getLargestStory(target.stories);
      largestStory.panel.split((Panel a, Panel b) {
        target
          ..replace(panel: largestStory.panel, withPanel: a)
          ..add(story: sourceStory, withPanel: b)
          ..normalizeSizes();
      });
      if (!largestStory.panel.canBeSplitVertically(_lastLayoutSize.width) &&
          !largestStory.panel.canBeSplitHorizontally(_lastLayoutSize.height)) {
        target.displayMode = DisplayMode.tabs;
      }
    }

    // We need to update the draggable id as in some cases this id could
    // be used by one of the cluster's stories.
    source.becomePlaceholder();
    target.clusterDraggableKey = new GlobalKey();
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Removes [storyCluster] from the list of story clusters.
  void remove(StoryCluster storyCluster) {
    storyCluster.becomePlaceholder();
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Called when a [StoryCluster] should be deleted.
  void delete(StoryCluster storyCluster) {
    onDeleteStoryCluster?.call(storyCluster.id);
  }

  /// Removes [storyToSplit] from [from]'s stories and updates [from]'s stories
  /// panels.  [storyToSplit] becomes forms its own [StoryCluster] which is
  /// added to the story cluster list.
  void split({required Story storyToSplit, required StoryCluster from}) {
    assert(from.stories.contains(storyToSplit));

    from.absorb(storyToSplit);

    clearPlaceHolderStoryClusters();
    StoryCluster newStoryCluster = new StoryCluster.fromStory(
      storyToSplit,
      from.onStoryClusterChanged ?? () {},
    );
    onStoryClusterAdded?.call(newStoryCluster);

    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Determines the max number of rows and columns based on [size] and either
  /// does nothing, rearrange the panels to fit, or switches to tabs.
  void normalize({required Size size}) {
    // TODO(apwilson): implement this!
  }

  /// Finds and returns the [StoryCluster] with the id equal to
  /// [storyClusterId], or null if it no longer exists (e.g. mid-drag merge).
  // ARMADILLAZARUS(parity): original used .single which crashes during drag
  // when clusters are mid-transition. Nullable per the original TODO.
  StoryCluster? getStoryCluster(StoryClusterId storyClusterId) => _storyClusters
      .where((StoryCluster storyCluster) => storyCluster.id == storyClusterId)
      .singleOrNull;

  /// Removes any [StoryCluster]s that consist of entirely place holder stories.
  void clearPlaceHolderStoryClusters() {
    _storyClusters
        .where((StoryCluster storyCluster) => storyCluster.realStories.isEmpty)
        .forEach((c) {
      onStoryClusterRemoved?.call(c);
    });

    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  Story _getLargestStory(List<Story> stories) {
    double largestSize = -0.0;
    Story? largestStory;
    for (Story story in stories) {
      double storySize = story.panel.sizeFactor;
      if (storySize > largestSize) {
        largestSize = storySize;
        largestStory = story;
      }
    }
    return largestStory!;
  }
}
