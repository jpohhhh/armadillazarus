// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'cluster_layout.dart';
import 'display_mode.dart';
import 'line_segment.dart';
import 'panel.dart';
import 'panel_drag_target.dart';
import 'panel_drag_targets.dart';
import 'story.dart';
import 'story_cluster.dart';

/// Two horizontal sets of targets are always at the top of the
/// [PanelDragTargets]:
/// 1. Story Bar Targets.
/// 2. Story Cluster Top Edge Target.
///
/// This is the gap to leave between them.
const double _kGapBetweenTopTargets = 48.0;

const double _kStoryBarTargetYOffset = 48.0;
const double _kTopEdgeTargetYOffset =
    _kStoryBarTargetYOffset + _kGapBetweenTopTargets + 16.0;
const double _kStoryTopEdgeTargetYOffset =
    _kTopEdgeTargetYOffset + _kGapBetweenTopTargets;
const double _kDiscardTargetHorizontalEdgeOffset = 48.0;

/// The distance inset story edge targets should be from the visual edge of the
/// story.
const double _kStoryEdgeTargetInset = 48.0;

/// The minimum distance inset story edge targets should be from each other.
const double _kStoryEdgeTargetInsetMinDistance = 0.0;

/// The height of the tab targets when in tabbed mode is increased by half
/// this amount; all targets directly below the tab targets are moved down by
/// this amount.
const double _kNonStoryBarTopTargetShiftWhenTabs = 48.0;

final Color _kDebugTopEdgeTargetColor = Colors.yellow[700]!;
final Color _kDebugLeftEdgeTargetColor = Colors.yellow[500]!;
final Color _kDebugBottomEdgeTargetColor = Colors.yellow[700]!;
final Color _kDebugRightEdgeTargetColor = Colors.yellow[500]!;
final List<Color> _kDebugStoryBarTargetColor = <Color>[
  Colors.grey[500]!,
  Colors.grey[700]!
];
final Color _kDebugDiscardTargetColor = Colors.red[700]!;
final Color _kDebugBringToFrontTargetColor = Colors.green[700]!;
final Color _kDebugTopStoryEdgeTargetColor = Colors.blue[100]!;
final Color _kDebugLeftStoryEdgeTargetColor = Colors.blue[300]!;
final Color _kDebugBottomStoryEdgeTargetColor = Colors.blue[500]!;
final Color _kDebugRightStoryEdgeTargetColor = Colors.blue[700]!;

/// Called when [storyCluster] is hovering over or dropped upon a target which
/// would result in the stories of [storyCluster] being placed to one side of
/// the target cluster.  If [preview] is true the resulting changes in the
/// target story cluster are temporary.
typedef OnPanelsEvent = void Function({
  required BuildContext context,
  required StoryCluster storyCluster,
  bool preview,
});

/// Called when [storyCluster] is hovering over or dropped upon a target which
/// would result in the stories of [storyCluster] being placed to one side of
/// [storyId]'s panel in the target cluster.  If [preview] is true the resulting
/// changes in the target story cluster are temporary.
typedef OnAddToPanelEvent = void Function({
  required BuildContext context,
  required StoryCluster storyCluster,
  required StoryId storyId,
  bool preview,
});

/// Called when [storyCluster] is being added to the target cluster's story bar
/// at the specified [targetIndex].
typedef OnStoryBarEvent = void Function({
  required BuildContext context,
  required StoryCluster storyCluster,
  required int targetIndex,
});

/// Called when [storyCluster] is being removed from the target cluster. If
/// [preview] is true the resulting changes in the target story cluster are
/// temporary.
typedef OnLeaveClusterEvent = void Function({
  required BuildContext context,
  required StoryCluster storyCluster,
  bool preview,
});

/// Generates targets for [PanelDragTargets].
class PanelDragTargetGenerator {
  /// Creates the targets for the configuration of panels represented by
  /// the story cluster's stories.
  ///
  /// Typically this includes the following targets:
  ///   1) Discard story target.
  ///   2) Bring to front target.
  ///   3) Convert to tabs target.
  ///   4) Edge targets on top, bottom, left, and right of the cluster.
  ///   5) Edge targets on top, bottom, left, and right of each panel.
  List<PanelDragTarget> createTargets({
    required Size size,
    required Size currentSize,
    required DisplayMode currentDisplayMode,
    required ClusterLayout clusterLayout,
    required double scale,
    required bool inTimeline,
    required int maxStories,
    required OnPanelsEvent onAddClusterAbovePanels,
    required OnPanelsEvent onAddClusterBelowPanels,
    required OnPanelsEvent onAddClusterToLeftOfPanels,
    required OnPanelsEvent onAddClusterToRightOfPanels,
    required OnAddToPanelEvent onAddClusterAbovePanel,
    required OnAddToPanelEvent onAddClusterBelowPanel,
    required OnAddToPanelEvent onAddClusterToLeftOfPanel,
    required OnAddToPanelEvent onAddClusterToRightOfPanel,
    required OnStoryBarEvent onStoryBarHover,
    required OnStoryBarEvent onStoryBarDrop,
    required OnLeaveClusterEvent onLeaveCluster,
  }) {
    List<LineSegment> targets = <LineSegment>[];
    double verticalMargin = (1.0 - scale) / 2.0 * size.height;
    double horizontalMargin = (1.0 - scale) / 2.0 * size.width;
    double verticalShift = currentDisplayMode == DisplayMode.tabs
        ? _kNonStoryBarTopTargetShiftWhenTabs
        : 0.0;

    List<Panel> panels = clusterLayout.panels;
    int availableRows = maxRows(size) - _getCurrentRows(panels: panels);
    if (availableRows > 0) {
      // Top edge target.
      targets
        ..add(
          new LineSegment.horizontal(
            name: 'Top edge target',
            y: verticalMargin + _kTopEdgeTargetYOffset + verticalShift,
            left: horizontalMargin + _kStoryEdgeTargetInsetMinDistance,
            right: size.width -
                horizontalMargin -
                _kStoryEdgeTargetInsetMinDistance,
            color: _kDebugTopEdgeTargetColor,
            maxStoriesCanAccept: availableRows,
            validityDistance: kMinPanelHeight,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterAbovePanels(
              context: context,
              storyCluster: storyCluster,
              preview: true,
            ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterAbovePanels(
              context: context,
              storyCluster: storyCluster,
              preview: false,
            ),
          ),
        )

        // Bottom edge target.
        ..add(
          new LineSegment.horizontal(
            name: 'Bottom edge target',
            y: size.height - verticalMargin,
            left: horizontalMargin + _kStoryEdgeTargetInsetMinDistance,
            right: size.width -
                horizontalMargin -
                _kStoryEdgeTargetInsetMinDistance,
            color: _kDebugBottomEdgeTargetColor,
            maxStoriesCanAccept: availableRows,
            validityDistance: kMinPanelHeight,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterBelowPanels(
              context: context,
              storyCluster: storyCluster,
              preview: true,
            ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterBelowPanels(
              context: context,
              storyCluster: storyCluster,
              preview: false,
            ),
          ),
        );
    }

    // Left edge target.
    int availableColumns =
        maxColumns(size) - _getCurrentColumns(panels: panels);
    if (availableColumns > 0) {
      targets
        ..add(
          new LineSegment.vertical(
            name: 'Left edge target',
            x: horizontalMargin,
            top: verticalMargin +
                _kTopEdgeTargetYOffset +
                _kStoryEdgeTargetInsetMinDistance +
                verticalShift,
            bottom: size.height -
                verticalMargin -
                _kStoryEdgeTargetInsetMinDistance,
            color: _kDebugLeftEdgeTargetColor,
            maxStoriesCanAccept: availableColumns,
            validityDistance: kMinPanelWidth,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterToLeftOfPanels(
              context: context,
              storyCluster: storyCluster,
              preview: true,
            ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterToLeftOfPanels(
              context: context,
              storyCluster: storyCluster,
              preview: false,
            ),
          ),
        )

        // Right edge target.
        ..add(
          new LineSegment.vertical(
            name: 'Right edge target',
            x: size.width - horizontalMargin,
            top: verticalMargin +
                _kTopEdgeTargetYOffset +
                _kStoryEdgeTargetInsetMinDistance +
                verticalShift,
            bottom: size.height -
                verticalMargin -
                _kStoryEdgeTargetInsetMinDistance,
            color: _kDebugRightEdgeTargetColor,
            maxStoriesCanAccept: availableColumns,
            validityDistance: kMinPanelWidth,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterToRightOfPanels(
              context: context,
              storyCluster: storyCluster,
              preview: true,
            ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                onAddClusterToRightOfPanels(
              context: context,
              storyCluster: storyCluster,
              preview: false,
            ),
          ),
        );
    }

    if (!inTimeline) {
      // Left return-to-timeline target.
      targets
        ..add(
          new LineSegment.vertical(
            name: 'Left return-to-timeline target',
            initiallyTargetable: false,
            x: verticalMargin + _kDiscardTargetHorizontalEdgeOffset,
            top: 0.0,
            bottom: size.height,
            color: _kDebugDiscardTargetColor,
            validityDistance:
                verticalMargin + _kDiscardTargetHorizontalEdgeOffset,
            maxStoriesCanAccept: maxStories,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                onLeaveCluster(
              context: context,
              storyCluster: storyCluster,
              preview: true,
            ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                onLeaveCluster(
              context: context,
              storyCluster: storyCluster,
              preview: false,
            ),
          ),
        )

        // Right return-to-timeline target.
        ..add(
          new LineSegment.vertical(
            name: 'Right return-to-timeline target',
            initiallyTargetable: false,
            x: size.width -
                verticalMargin -
                _kDiscardTargetHorizontalEdgeOffset,
            top: 0.0,
            bottom: size.height,
            color: _kDebugBringToFrontTargetColor,
            validityDistance:
                verticalMargin + _kDiscardTargetHorizontalEdgeOffset,
            maxStoriesCanAccept: maxStories,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                onLeaveCluster(
              context: context,
              storyCluster: storyCluster,
              preview: true,
            ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                onLeaveCluster(
              context: context,
              storyCluster: storyCluster,
              preview: false,
            ),
          ),
        );
    }

    // Story Bar targets.
    int storyBarTargets = clusterLayout.storyCount + 1;
    double storyBarTargetLeft = 0.0;
    final double storyBarTargetWidth =
        (size.width - 2.0 * horizontalMargin) / storyBarTargets;
    for (int i = 0; i < storyBarTargets; i++) {
      double lineWidth = storyBarTargetWidth +
          ((i == 0 || i == storyBarTargets - 1) ? horizontalMargin : 0.0);
      targets.add(
        new LineSegment.horizontal(
          name: 'Story Bar target for index $i',
          y: verticalMargin + _kStoryBarTargetYOffset,
          left: storyBarTargetLeft,
          right: storyBarTargetLeft + lineWidth,
          color:
              _kDebugStoryBarTargetColor[i % _kDebugStoryBarTargetColor.length],
          validityDistance:
              verticalMargin + _kStoryBarTargetYOffset + verticalShift,
          maxStoriesCanAccept: maxStories,
          onHover: (BuildContext context, StoryCluster storyCluster) =>
              onStoryBarHover(
            context: context,
            storyCluster: storyCluster,
            targetIndex: i,
          ),
          onDrop: (BuildContext context, StoryCluster storyCluster) =>
              onStoryBarDrop(
            context: context,
            storyCluster: storyCluster,
            targetIndex: i,
          ),
        ),
      );
      storyBarTargetLeft += lineWidth;
    }

    // Story edge targets.
    Offset center = new Offset(size.width / 2.0, size.height / 2.0);
    clusterLayout.visitStories((StoryId storyId, Panel storyPanel) {
      Rect bounds = _transform(storyPanel, center, size, scale);

      // If we can split vertically add vertical targets on left and right.
      int verticalSplits = _getVerticalSplitCount(storyPanel, size, panels);
      if (verticalSplits > 0) {
        double left = bounds.left + _kStoryEdgeTargetInset;
        double right = bounds.right - _kStoryEdgeTargetInset;
        double top = bounds.top +
            _kStoryEdgeTargetInsetMinDistance +
            (storyPanel.top == 0.0
                ? _kStoryTopEdgeTargetYOffset + verticalShift
                : 2.0 * _kStoryEdgeTargetInset);
        double bottom = bounds.bottom -
            _kStoryEdgeTargetInsetMinDistance -
            _kStoryEdgeTargetInset;

        // Add left target.
        targets
          ..add(
            new LineSegment.vertical(
              name: 'Add left target $storyId',
              x: left,
              top: top,
              bottom: bottom,
              color: _kDebugLeftStoryEdgeTargetColor,
              maxStoriesCanAccept: verticalSplits,
              validityDistance: kMinPanelWidth,
              directionallyTargetable: true,
              onHover: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterToLeftOfPanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: true,
              ),
              onDrop: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterToLeftOfPanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: false,
              ),
            ),
          )

          // Add right target.
          ..add(
            new LineSegment.vertical(
              name: 'Add right target $storyId',
              x: right,
              top: top,
              bottom: bottom,
              color: _kDebugRightStoryEdgeTargetColor,
              maxStoriesCanAccept: verticalSplits,
              validityDistance: kMinPanelWidth,
              directionallyTargetable: true,
              onHover: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterToRightOfPanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: true,
              ),
              onDrop: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterToRightOfPanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: false,
              ),
            ),
          );
      }

      // If we can split horizontally add horizontal targets on top and bottom.
      int horizontalSplits = _getHorizontalSplitCount(storyPanel, size, panels);
      if (horizontalSplits > 0) {
        double top = bounds.top +
            (storyPanel.top == 0.0
                ? _kStoryTopEdgeTargetYOffset + verticalShift
                : _kStoryEdgeTargetInset);
        double left = bounds.left +
            _kStoryEdgeTargetInsetMinDistance +
            _kStoryEdgeTargetInset;
        double right = bounds.right -
            _kStoryEdgeTargetInsetMinDistance -
            _kStoryEdgeTargetInset;
        double bottom = bounds.bottom - _kStoryEdgeTargetInset;

        // Add top target.
        targets
          ..add(
            new LineSegment.horizontal(
              name: 'Add top target $storyId',
              y: top,
              left: left,
              right: right,
              color: _kDebugTopStoryEdgeTargetColor,
              maxStoriesCanAccept: horizontalSplits,
              validityDistance: kMinPanelHeight,
              directionallyTargetable: true,
              onHover: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterAbovePanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: true,
              ),
              onDrop: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterAbovePanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: false,
              ),
            ),
          )

          // Add bottom target.
          ..add(
            new LineSegment.horizontal(
              name: 'Add bottom target $storyId',
              y: bottom,
              left: left,
              right: right,
              color: _kDebugBottomStoryEdgeTargetColor,
              maxStoriesCanAccept: horizontalSplits,
              validityDistance: kMinPanelHeight,
              directionallyTargetable: true,
              onHover: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterBelowPanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: true,
              ),
              onDrop: (BuildContext context, StoryCluster storyCluster) =>
                  onAddClusterBelowPanel(
                context: context,
                storyCluster: storyCluster,
                storyId: storyId,
                preview: false,
              ),
            ),
          );
      }
    });

    // All of the above LineSegments have been created assuming the cluster
    // as at the size specified by the sizeModel.  Since that's not always the
    // case (particularly when we're doing an inline preview) we need to scale
    // down all the lines when our current size doesn't match our expected size.
    double horizontalScale = currentSize.width / size.width;
    double verticalScale = currentSize.height / size.height;
    if (horizontalScale != 1.0 || verticalScale != 1.0) {
      List<LineSegment> scaledTargets = targets
          .map(
            (LineSegment lineSegment) => new LineSegment(
              new Offset(
                lerpDouble(0.0, lineSegment.a.dx, horizontalScale)!,
                lerpDouble(0.0, lineSegment.a.dy, verticalScale)!,
              ),
              new Offset(
                lerpDouble(0.0, lineSegment.b.dx, horizontalScale)!,
                lerpDouble(0.0, lineSegment.b.dy, verticalScale)!,
              ),
              name: lineSegment.name,
              color: lineSegment.color,
              onHover: lineSegment.onHover,
              onDrop: lineSegment.onDrop,
              maxStoriesCanAccept: lineSegment.maxStoriesCanAccept,
              initiallyTargetable: lineSegment.initiallyTargetable,
              directionallyTargetable: lineSegment.directionallyTargetable,
              validityDistance: lerpDouble(
                0.0,
                lineSegment.validityDistance,
                lineSegment.isHorizontal ? verticalScale : horizontalScale,
              )!,
            ),
          )
          .toList();
      return scaledTargets;
    }
    return targets;
  }

  /// For a layout specified by [panels], returns the number of rows that
  /// layout consists of.  This is used to ensure we don't allow too many rows
  /// to be created.
  int _getCurrentRows({required List<Panel> panels}) =>
      _getRows(left: 0.0, right: 1.0, panels: panels);

  /// For a layout specified by [panels], returns the number of columns that
  /// layout consists of.  This is used to ensure we don't allow too many
  /// columns to be created.
  int _getCurrentColumns({required List<Panel> panels}) =>
      _getColumns(top: 0.0, bottom: 1.0, panels: panels);

  int _getRows(
      {required double left,
      required double right,
      required List<Panel> panels}) {
    Set<double> tops = new Set<double>();
    for (Panel panel in panels.where(
      (Panel panel) =>
          (left <= panel.left && right > panel.left) ||
          (panel.left < left && panel.right > left),
    )) {
      tops.add(panel.top);
    }
    return tops.length;
  }

  int _getColumns(
      {required double top,
      required double bottom,
      required List<Panel> panels}) {
    Set<double> lefts = new Set<double>();
    for (Panel panel in panels.where(
      (Panel panel) =>
          (top <= panel.top && bottom > panel.top) ||
          (top < panel.top && panel.bottom > top),
    )) {
      lefts.add(panel.left);
    }
    return lefts.length;
  }

  int _getHorizontalSplitCount(
    Panel panel,
    Size fullSize,
    List<Panel> panels,
  ) =>
      maxRows(fullSize) -
      _getRows(
        left: panel.left,
        right: panel.right,
        panels: panels,
      );

  int _getVerticalSplitCount(Panel panel, Size fullSize, List<Panel> panels) =>
      maxColumns(fullSize) -
      _getColumns(
        top: panel.top,
        bottom: panel.bottom,
        panels: panels,
      );

  Rect _bounds(Panel panel, Size size) => new Rect.fromLTRB(
        panel.left * size.width,
        panel.top * size.height,
        panel.right * size.width,
        panel.bottom * size.height,
      );

  Rect _transform(Panel panel, Offset origin, Size size, double scale) =>
      Rect.lerp(origin & Size.zero, _bounds(panel, size), scale)!;
}
