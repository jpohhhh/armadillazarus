// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/common.dart';

import 'panel_drag_targets.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

/// A [Story] with no content.  This is used in place of a real story within a
/// [StoryCluster] to take up empty visual space in [StoryPanels] when
/// [PanelDragTargets] has a hovering cluster (ie. we're previewing the
/// combining of two clusters).
class PlaceHolderStory extends Story {
  /// The [StoryId] of the [Story] this place holder replacing.
  final StoryId associatedStoryId;

  /// Constructor.
  PlaceHolderStory({required this.associatedStoryId})
      : super(
          id: new StoryId('PlaceHolder $associatedStoryId'),
          widget: Nothing.widget,
        );

  @override
  bool get isPlaceHolder => true;
}
