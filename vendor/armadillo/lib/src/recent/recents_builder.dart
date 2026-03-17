// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:armadillo/common.dart';
import 'package:armadillo/now.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'armadillo_overlay.dart';
import 'edge_scroll_drag_target.dart';
import 'scroll_locker.dart';
import 'story_cluster.dart';
import 'story_drag_transition_model.dart';
import 'story_list.dart';
import 'story_model.dart';

/// If the user releases their finger when overscrolled more than this amount,
/// we snap suggestions open.
const double _kOverscrollAutoSnapThreshold = -250.0;

/// If the user releases their finger when overscrolled more than this amount
/// and  the user dragged their finger at least
/// [_kOverscrollSnapDragDistanceThreshold], we snap suggestions open.
const double _kOverscrollSnapDragThreshold = -50.0;

/// See [_kOverscrollSnapDragThreshold].
const double _kOverscrollSnapDragDistanceThreshold = 200.0;

/// Builds recents.
class RecentsBuilder {
  final ScrollLockerModel _scrollLockerModel = new ScrollLockerModel();
  final GlobalKey<ArmadilloOverlayState> _overlayKey =
      new GlobalKey<ArmadilloOverlayState>();
  final EdgeScrollDragTargetModel _edgeScrollDragTargetModel;
  final ScrollController _scrollController;

  /// Constructor.
  factory RecentsBuilder() {
    ScrollController scrollController = new ScrollController();
    return new RecentsBuilder._create(
        scrollController,
        new EdgeScrollDragTargetModel(
          scrollController: scrollController,
        ));
  }

  RecentsBuilder._create(
    this._scrollController,
    this._edgeScrollDragTargetModel,
  );

  /// Builds recents.
  Widget build(
    BuildContext context, {
    ValueChanged<double>? onScroll,
    VoidCallback? onStoryClusterVerticalEdgeHover,
  }) =>
      _buildRecents(
        context,
        onScroll: onScroll,
        onStoryClusterVerticalEdgeHover: onStoryClusterVerticalEdgeHover,
      );

  Widget _buildRecents(
    BuildContext context, {
    ValueChanged<double>? onScroll,
    VoidCallback? onStoryClusterVerticalEdgeHover,
  }) =>
      new Stack(
        children: <Widget>[
          new ScopedModelDescendant<SizeModel>(
            builder: (_, __, SizeModel sizeModel) =>
                new ScopedModelDescendant<StoryDragTransitionModel>(
              builder: (
                BuildContext context,
                Widget? child,
                StoryDragTransitionModel storyDragTransitionModel,
              ) =>
                  new Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                bottom: lerpDouble(
                  sizeModel.minimizedNowHeight,
                  0.0,
                  storyDragTransitionModel.value,
                )!,
                child: child!,
              ),
              child: new VerticalShifter(
                verticalShift: NowBuilder.kQuickSettingsHeightBump,
                child: new ScrollLocker(
                  model: _scrollLockerModel,
                  child: new StoryList(
                    scrollController: _scrollController,
                    overlayKey: _overlayKey,
                    onScroll: onScroll,
                    onStoryClusterVerticalEdgeHover:
                        onStoryClusterVerticalEdgeHover,
                  ),
                ),
              ),
            ),
          ),

          // Top and bottom edge scrolling drag targets.
          new Positioned.fill(
            child: new EdgeScrollDragTarget(model: _edgeScrollDragTargetModel),
          ),
        ],
      );

  /// Call when a story cluster comes into focus.
  void onStoryFocused() {
    _scrollLockerModel.lock();
    _edgeScrollDragTargetModel.disable();
  }

  /// Call when a story cluster leaves focus.
  void onStoryUnfocused() {
    _scrollLockerModel.unlock();
    _edgeScrollDragTargetModel.enable();
  }

  /// Call to reset the recents scrolling to 0.0.
  void resetScroll({bool jump = false}) {
    if (jump) {
      _scrollController.jumpTo(0.0);
    } else {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  /// Indicates if we're significantly overscrolled for the given
  /// [dragDistance].
  bool isSignificantlyOverscrolled(double dragDistance) =>
      _scrollController.offset < _kOverscrollAutoSnapThreshold ||
      (_scrollController.offset < _kOverscrollSnapDragThreshold &&
          dragDistance > _kOverscrollSnapDragDistanceThreshold);
}
