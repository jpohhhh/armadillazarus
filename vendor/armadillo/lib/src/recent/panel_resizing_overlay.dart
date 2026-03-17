// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'long_press_gesture_detector.dart';
import 'panel.dart';
import 'panel_resizing_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_panels_model.dart';
import 'story_positioned.dart';

const double _kDragTargetSize = 24.0;

const Color _kGestureDetectorColor = const Color(0x00800080);

/// Adds gesture detectors between [storyCluster]'s panels to allow them to be
/// resized with a horizontal or vertical drag.  These gesture detectors are
/// overlayed on top of [child].
class PanelResizingOverlay extends StatelessWidget {
  /// The cluster whose panels are to be resized.
  final StoryCluster storyCluster;

  /// The cluster's widget.
  final Widget child;

  /// The current size of the cluster's widget.
  final Size currentSize;

  /// True if the overlay should respond to resizing events.
  final bool enabled;

  /// Constructor.
  const PanelResizingOverlay({
    Key? key,
    required this.storyCluster,
    required this.child,
    required this.currentSize,
    required this.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<StoryClusterPanelsModel>(
        builder: (
          BuildContext context,
          Widget? child,
          StoryClusterPanelsModel storyClusterPanelsModel,
        ) =>
            _buildWidget(context, storyClusterPanelsModel),
      );

  Widget _buildWidget(
    BuildContext context,
    StoryClusterPanelsModel storyClusterPanelsModel,
  ) {
    // For each panel, look at its right and bottom.  If not 1.0, find the
    // panels on the other side of that edge.  If 1:many or many:1
    Set<double> rights = new Set<double>();
    Set<double> bottoms = new Set<double>();
    for (Panel panel in storyCluster.panels) {
      if (panel.right != 1.0) {
        rights.add(panel.right);
      }

      if (panel.bottom != 1.0) {
        bottoms.add(panel.bottom);
      }
    }

    List<Widget> stackChildren = <Widget>[child];

    if (enabled) {
      // Create draggables for each vertical seam.
      List<_VerticalSeam> verticalSeams = _getVerticalSeams(
        context,
        rights,
        storyClusterPanelsModel,
      );
      stackChildren.addAll(
        verticalSeams.map(
          (_VerticalSeam verticalSeam) => new Positioned.fill(
            child: verticalSeam.build(context),
          ),
        ),
      );

      // Create draggables for each horizontal seam.
      List<_HorizontalSeam> horizontalSeams =
          _getHorizontalSeams(context, bottoms, storyClusterPanelsModel);
      stackChildren.addAll(
        horizontalSeams.map(
          (_HorizontalSeam horizontalSeam) => new Positioned.fill(
            child: horizontalSeam.build(context),
          ),
        ),
      );
    }

    return new Stack(
      children: stackChildren,
      fit: StackFit.passthrough,
    );
  }

  /// For each element of [rights], find the set of panels that touch that
  /// element with their right or left and create a [_VerticalSeam] from them.
  /// There can be multiple [_VerticalSeam]s for a right if the panels on the
  /// left and right don't overlap contiguously.
  List<_VerticalSeam> _getVerticalSeams(
    BuildContext context,
    Set<double> rights,
    StoryClusterPanelsModel storyClusterPanelsModel,
  ) {
    List<_VerticalSeam> verticalSeams = <_VerticalSeam>[];
    for (double right in rights) {
      List<Panel> touchingPanels = storyCluster.panels
          .where((Panel panel) => panel.left == right || panel.right == right)
          .toList()
        ..sort(
          (Panel a, Panel b) => a.top < b.top
              ? -1
              : a.top > b.top
                  ? 1
                  : 0,
        );
      // Start first span.
      double top = touchingPanels.first.top;
      double bottom = touchingPanels.first.bottom;
      List<Panel> panelsToLeft = <Panel>[];
      List<Panel> panelsToRight = <Panel>[];
      for (Panel panel in touchingPanels) {
        if (panel.top < bottom) {
          if (panel.bottom > bottom) {
            bottom = panel.bottom;
          }
        } else {
          // Store span, start new span.
          verticalSeams.add(
            new _VerticalSeam(
              x: right,
              top: top,
              bottom: bottom,
              panelsToLeft: panelsToLeft,
              panelsToRight: panelsToRight,
              onPanelsChanged: () => _onPanelsChanged(
                context,
                storyClusterPanelsModel,
              ),
              panelResizingModel: PanelResizingModel.of(context),
            ),
          );

          top = panel.top;
          bottom = panel.bottom;
          panelsToLeft = <Panel>[];
          panelsToRight = <Panel>[];
        }
        if (panel.left == right) {
          panelsToRight.add(panel);
        } else {
          panelsToLeft.add(panel);
        }
      }
      // Store last span.
      verticalSeams.add(
        new _VerticalSeam(
          x: right,
          top: top,
          bottom: bottom,
          panelsToLeft: panelsToLeft,
          panelsToRight: panelsToRight,
          onPanelsChanged: () => _onPanelsChanged(
            context,
            storyClusterPanelsModel,
          ),
          panelResizingModel: PanelResizingModel.of(context),
        ),
      );
    }
    return verticalSeams;
  }

  /// For each element of [bottoms], find the set of panels that touch that
  /// element with their top or bottom and create a [_HorizontalSeam] from them.
  /// There can be multiple [_HorizontalSeam]s for a bottom if the panels on the
  /// top and bottom don't overlap contiguously.
  List<_HorizontalSeam> _getHorizontalSeams(
    BuildContext context,
    Set<double> bottoms,
    StoryClusterPanelsModel storyClusterPanelsModel,
  ) {
    List<_HorizontalSeam> horizontalSeams = <_HorizontalSeam>[];
    for (double bottom in bottoms) {
      List<Panel> touchingPanels = storyCluster.panels
          .where((Panel panel) => panel.top == bottom || panel.bottom == bottom)
          .toList()
        ..sort(
          (Panel a, Panel b) => a.left < b.left
              ? -1
              : a.left > b.left
                  ? 1
                  : 0,
        );
      // Start first span.
      double left = touchingPanels.first.left;
      double right = touchingPanels.first.right;
      List<Panel> panelsAbove = <Panel>[];
      List<Panel> panelsBelow = <Panel>[];
      for (Panel panel in touchingPanels) {
        if (panel.left < right) {
          if (panel.right > right) {
            right = panel.right;
          }
        } else {
          // Store span, start new span.
          horizontalSeams.add(
            new _HorizontalSeam(
              y: bottom,
              left: left,
              right: right,
              panelsAbove: panelsAbove,
              panelsBelow: panelsBelow,
              onPanelsChanged: () => _onPanelsChanged(
                context,
                storyClusterPanelsModel,
              ),
              panelResizingModel: PanelResizingModel.of(context),
            ),
          );

          left = panel.left;
          right = panel.right;
          panelsAbove = <Panel>[];
          panelsBelow = <Panel>[];
        }
        if (panel.top == bottom) {
          panelsBelow.add(panel);
        } else {
          panelsAbove.add(panel);
        }
      }
      // Store last span.
      horizontalSeams.add(
        new _HorizontalSeam(
          y: bottom,
          left: left,
          right: right,
          panelsAbove: panelsAbove,
          panelsBelow: panelsBelow,
          onPanelsChanged: () => _onPanelsChanged(
            context,
            storyClusterPanelsModel,
          ),
          panelResizingModel: PanelResizingModel.of(context),
        ),
      );
    }
    return horizontalSeams;
  }

  void _onPanelsChanged(
    BuildContext context,
    StoryClusterPanelsModel storyClusterPanelsModel,
  ) {
    for (Story story in storyCluster.stories) {
      EdgeInsets margins = StoryPositioned.getFractionalMargins(
        story.panel,
        currentSize,
        1.0,
        PanelResizingModel.of(context),
      );
      story.positionedKey.currentState!.jumpToValues(
        fractionalTop: story.panel.top + margins.top,
        fractionalLeft: story.panel.left + margins.left,
        fractionalWidth: story.panel.width - (margins.left + margins.right),
        fractionalHeight: story.panel.height - (margins.top + margins.bottom),
      );
    }
    storyClusterPanelsModel.notifyListeners();
  }
}

/// Holds the information about a vertical seam between two sets of panels.
/// [x] is the horizontal position of the seam.
/// The seam spans from [top] to [bottom] on the vertical axis.
/// [panelsToLeft] are the [Panel]s to the lest of the seam.
/// [panelsToRight] are the [Panel]s to the right of the seam.
/// When a drag happens [panelsToLeft] and [panelsToRight] will be resized and
/// [onPanelsChanged] will be called.
/// [x], [top], and [bottom] are all specified in fractional values.
class _VerticalSeam {
  final double x;
  final double top;
  final double bottom;
  final List<Panel> panelsToLeft;
  final List<Panel> panelsToRight;
  final VoidCallback onPanelsChanged;
  final ResizingState resizingState;

  _VerticalSeam({
    required this.x,
    required this.top,
    required this.bottom,
    required this.panelsToLeft,
    required this.panelsToRight,
    required this.onPanelsChanged,
    required PanelResizingModel panelResizingModel,
  }) : resizingState = panelResizingModel.getState(<Side, List<Panel>>{
              Side.right: panelsToLeft,
              Side.left: panelsToRight,
            }) ??
            new ResizingState(<Side, List<Panel>>{
              Side.right: panelsToLeft,
              Side.left: panelsToRight,
            });

  /// Creates a [Widget] representing this seam which can be dragged.
  Widget build(BuildContext context) => new CustomSingleChildLayout(
        delegate: new _VerticalSeamLayoutDelegate(
          x: x,
          top: top,
          bottom: bottom,
        ),
        child: new Container(
          color: _kGestureDetectorColor,
          child: new LongPressGestureDetector(
            child: const SizedBox.expand(),
            onDragStart: (DragStartDetails details) {
              resizingState
                ..valueOnDrag = x
                ..dragDelta = 0.0;
              PanelResizingModel.of(context).resizeBegin(resizingState);
            },
            onDragEnd: (DragEndDetails details) {
              PanelResizingModel.of(context).resizeEnd(resizingState);
            },
            onDragCancel: () {
              PanelResizingModel.of(context).resizeEnd(resizingState);
            },
            onDragUpdate: (DragUpdateDetails details) {
              double deltaX = details.delta.dx;
              resizingState.dragDelta += deltaX;

              RenderBox box = context.findRenderObject()! as RenderBox;

              double newX = toGridValue(
                resizingState.valueOnDrag +
                    (resizingState.dragDelta / box.size.width),
              );

              if (panelsToLeft.every(
                    (Panel panel) => panel.canAdjustRight(
                      newX,
                      box.size.width,
                    ),
                  ) &&
                  panelsToRight.every(
                    (Panel panel) => panel.canAdjustLeft(
                      newX,
                      box.size.width,
                    ),
                  )) {
                for (Panel panel in panelsToLeft) {
                  panel.adjustRight(newX);
                }
                for (Panel panel in panelsToRight) {
                  panel.adjustLeft(newX);
                }
                onPanelsChanged();
              }
            },
          ),
        ),
      );

  @override
  String toString() => 'VerticalSeam($x: $top => $bottom)\n'
      '\tpanelsToLeft: $panelsToLeft\n'
      '\tpanelsToRight: $panelsToRight';
}

/// Positions and sizes a vertical seam.
class _VerticalSeamLayoutDelegate extends SingleChildLayoutDelegate {
  final double x;
  final double top;
  final double bottom;

  _VerticalSeamLayoutDelegate(
      {required this.x, required this.top, required this.bottom});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      new BoxConstraints.tightFor(
        width: _kDragTargetSize,
        height: (bottom - top) * constraints.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => new Offset(
        x * size.width - _kDragTargetSize / 2.0,
        top * size.height,
      );

  @override
  bool shouldRelayout(_VerticalSeamLayoutDelegate oldDelegate) =>
      oldDelegate.top != top ||
      oldDelegate.bottom != bottom ||
      oldDelegate.x != x;
}

/// Holds the information about a horizontal seam between two sets of panels.
/// [y] is the vertical position of the seam.
/// The seam spans from [left] to [right] on the horizontal axis.
/// [panelsAbove] are the [Panel]s above the seam.
/// [panelsBelow] are the [Panel]s below the seam.
/// When a drag happens [panelsAbove] and [panelsBelow] will be resized and
/// [onPanelsChanged] will be called.
/// [y], [left], and [right] are all specified in fractional values.
class _HorizontalSeam {
  final double y;
  final double left;
  final double right;
  final List<Panel> panelsAbove;
  final List<Panel> panelsBelow;
  final VoidCallback onPanelsChanged;
  final ResizingState resizingState;

  _HorizontalSeam({
    required this.y,
    required this.left,
    required this.right,
    required this.panelsAbove,
    required this.panelsBelow,
    required this.onPanelsChanged,
    required PanelResizingModel panelResizingModel,
  }) : resizingState = panelResizingModel.getState(<Side, List<Panel>>{
              Side.bottom: panelsAbove,
              Side.top: panelsBelow,
            }) ??
            new ResizingState(<Side, List<Panel>>{
              Side.bottom: panelsAbove,
              Side.top: panelsBelow,
            });

  /// Creates a [Widget] representing this seam which can be dragged.
  Widget build(BuildContext context) => new CustomSingleChildLayout(
        delegate: new _HorizontalSeamLayoutDelegate(
          y: y,
          left: left,
          right: right,
        ),
        child: new Container(
          color: _kGestureDetectorColor,
          child: new LongPressGestureDetector(
            child: const SizedBox.expand(),
            onDragStart: (DragStartDetails details) {
              resizingState
                ..valueOnDrag = y
                ..dragDelta = 0.0;
              PanelResizingModel.of(context).resizeBegin(resizingState);
            },
            onDragEnd: (DragEndDetails details) {
              PanelResizingModel.of(context).resizeEnd(resizingState);
            },
            onDragCancel: () {
              PanelResizingModel.of(context).resizeEnd(resizingState);
            },
            onDragUpdate: (DragUpdateDetails details) {
              double deltaY = details.delta.dy;
              resizingState.dragDelta += deltaY;
              RenderBox box = context.findRenderObject()! as RenderBox;

              double newY = toGridValue(
                resizingState.valueOnDrag +
                    (resizingState.dragDelta / box.size.height),
              );

              if (panelsAbove.every(
                    (Panel panel) => panel.canAdjustBottom(
                      newY,
                      box.size.height,
                    ),
                  ) &&
                  panelsBelow.every(
                    (Panel panel) => panel.canAdjustTop(
                      newY,
                      box.size.height,
                    ),
                  )) {
                for (Panel panel in panelsAbove) {
                  panel.adjustBottom(newY);
                }
                for (Panel panel in panelsBelow) {
                  panel.adjustTop(newY);
                }
                onPanelsChanged();
              }
            },
          ),
        ),
      );

  @override
  String toString() => 'HorizontalSeam($y: $left => $right)\n'
      '\tpanelsAbove: $panelsAbove\n'
      '\tpanelsBelow: $panelsBelow';
}

/// Positions and sizes a horizontal seam.
class _HorizontalSeamLayoutDelegate extends SingleChildLayoutDelegate {
  final double y;
  final double left;
  final double right;

  _HorizontalSeamLayoutDelegate(
      {required this.y, required this.left, required this.right});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      new BoxConstraints.tightFor(
        width: (right - left) * constraints.maxWidth,
        height: _kDragTargetSize,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => new Offset(
        left * size.width,
        y * size.height - _kDragTargetSize / 2.0,
      );

  @override
  bool shouldRelayout(_HorizontalSeamLayoutDelegate oldDelegate) =>
      oldDelegate.left != left ||
      oldDelegate.right != right ||
      oldDelegate.y != y;
}
