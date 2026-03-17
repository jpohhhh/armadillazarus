// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'story_cluster_id.dart';
import 'story_list.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Tracks which story clusters are currently being dragged.  This is used by
/// some UI elements to scale ([StoryList]), fade out ([Now]), or slide away
/// ([PeekingOverlay]).
class StoryClusterDragStateModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static StoryClusterDragStateModel of(BuildContext context) =>
      new ModelFinder<StoryClusterDragStateModel>().of(context);

  final Set<StoryClusterId> _draggingStoryClusters = new Set<StoryClusterId>();
  final Set<StoryClusterId> _acceptingStoryClusters = new Set<StoryClusterId>();

  /// Returns true if a story cluster is being dragged.
  bool get isDragging => _draggingStoryClusters.isNotEmpty;

  /// Returns true if a story cluster is being dragged and another
  /// story cluster is accepting it.
  bool get isAccepting => _acceptingStoryClusters.isNotEmpty;

  /// Returns true if the given story cluster is accepting another
  /// story cluster.
  bool isStoryClusterAccepting(StoryClusterId id) =>
      _acceptingStoryClusters.contains(id);

  /// Registers [storyClusterId] as being dragged.
  void addDragging(StoryClusterId storyClusterId) {
    bool isDraggingBefore = isDragging;
    _draggingStoryClusters.add(storyClusterId);
    if (isDragging != isDraggingBefore) {
      notifyListeners();
    }
  }

  /// Registers [storyClusterId] as no longer being dragged.
  void removeDragging(StoryClusterId storyClusterId) {
    bool isDraggingBefore = isDragging;
    _draggingStoryClusters.remove(storyClusterId);
    if (isDragging != isDraggingBefore) {
      notifyListeners();
    }
  }

  /// Registers [storyClusterId] as accepting another story cluster.
  void addAcceptance(StoryClusterId storyClusterId) {
    bool isAcceptingBefore = isAccepting;
    _acceptingStoryClusters.add(storyClusterId);
    if (isAccepting != isAcceptingBefore) {
      notifyListeners();
    }
  }

  /// Registers [storyClusterId] as no longer accepting another story cluster.
  void removeAcceptance(StoryClusterId storyClusterId) {
    bool isAcceptingBefore = isAccepting;
    _acceptingStoryClusters.remove(storyClusterId);
    if (isAccepting != isAcceptingBefore) {
      notifyListeners();
    }
  }
}
