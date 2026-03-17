// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:armadillo/common.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'armadillo_drag_target.dart';
import 'kenichi_edge_scrolling.dart';
import 'story_cluster_drag_data.dart';
import 'story_cluster_drag_state_model.dart';

const Color _kDraggableHoverColor = const Color(0x00FFFF00);
const Color _kNoDraggableHoverColor = const Color(0x00FFFF00);

/// Creates disablable drag targets which cause the given [ScrollController] to
/// scroll when a draggable hovers over them.  The drag targets are placed
/// at the top and bottom of this widget's parent such that dragging a candidate
/// to the top or bottom 'edge' of the parent will trigger scrolling.
class EdgeScrollDragTarget extends StatelessWidget {
  /// The state of the EdgeScrollDragTarget.
  final EdgeScrollDragTargetModel model;

  /// Constructor.
  const EdgeScrollDragTarget({required this.model});

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
        animation: model,
        builder: (BuildContext context, Widget? child) =>
            new ScopedModelDescendant<StoryClusterDragStateModel>(
          builder: (
            BuildContext context,
            Widget? child,
            StoryClusterDragStateModel storyClusterDragStateModel,
          ) {
            bool isNotDragging =
                !model.enabled || !storyClusterDragStateModel.isDragging;
            if (isNotDragging) {
              model.onNoDrag();
            }
            return isNotDragging ? Nothing.widget : child!;
          },
          child: new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new Positioned(
                top: 0.0,
                left: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: _buildDragTarget(
                  onBuild: (bool hasDraggableAbove, List<Offset> points) {
                    RenderBox box = context.findRenderObject()! as RenderBox;
                    double height = box.size.height;
                    double y = height;
                    for (Offset point in points) {
                      y = math.min(y, point.dy);
                    }
                    model.update(y, height);
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDragTarget({
    Key? key,
    void Function(bool hasDraggableAbove, List<Offset> points)? onBuild,
  }) =>
      new ArmadilloDragTarget<StoryClusterDragData>(
        onWillAccept: (_, __) => false,
        onAccept: (_, __, ___) => null,
        builder: (_, __, Map<dynamic, Offset> rejectedData) {
          onBuild?.call(rejectedData.isNotEmpty, rejectedData.values.toList());
          return new IgnorePointer(
            child: new Container(
              color: rejectedData.isEmpty
                  ? _kNoDraggableHoverColor
                  : _kDraggableHoverColor,
            ),
          );
        },
      );
}

/// [State] of [EdgeScrollDragTarget].
class EdgeScrollDragTargetModel extends TickingModel {
  /// The [ScrollController] that will have its scroll offset change due to
  /// dragging a candidate to the edge of this [EdgeScrollDragTarget].
  final ScrollController scrollController;

  final KenichiEdgeScrolling _kenichiEdgeScrolling = new KenichiEdgeScrolling();
  bool _enabled = true;

  /// Constructor.
  EdgeScrollDragTargetModel({required this.scrollController});

  /// Disables detection of candidates over the top and bottom edges of its
  /// parent.
  void disable() {
    if (_enabled) {
      _enabled = false;
      notifyListeners();
    }
  }

  /// Enables detection of candidates over the top and bottom edges of its
  /// parent.
  void enable() {
    if (!_enabled) {
      _enabled = true;
      notifyListeners();
    }
  }

  /// Call when nothing is being dragged.
  void onNoDrag() {
    _kenichiEdgeScrolling.onNoDrag();
  }

  /// Updates edge scrolling based on current touch location relative to height.
  void update(double y, double height) {
    _kenichiEdgeScrolling.update(y, height);
    if (!_kenichiEdgeScrolling.isDone) {
      startTicking();
    }
  }

  /// Returns true if edge scrolling is enabled.
  bool get enabled => _enabled;

  @override
  bool handleTick(double seconds) {
    // Cancel callbacks if we've disabled the drag targets or we've settled.
    if (!_enabled || _kenichiEdgeScrolling.isDone) {
      return false;
    }

    ScrollPosition position = scrollController.position;
    double minScrollExtent = position.minScrollExtent;
    double maxScrollExtent = position.maxScrollExtent;
    double currentScrollOffset = position.pixels;

    double cumulativeScrollDelta = 0.0;
    double secondsRemaining = seconds;
    const double _kMaxStepSize = 1 / 60;
    while (secondsRemaining > 0.0) {
      double stepSize =
          secondsRemaining > _kMaxStepSize ? _kMaxStepSize : secondsRemaining;
      cumulativeScrollDelta += _kenichiEdgeScrolling.getScrollDelta(stepSize);
      secondsRemaining -= _kMaxStepSize;
    }
    scrollController.jumpTo(
      (currentScrollOffset + cumulativeScrollDelta).clamp(
        minScrollExtent,
        maxScrollExtent,
      ),
    );
    return true;
  }
}
