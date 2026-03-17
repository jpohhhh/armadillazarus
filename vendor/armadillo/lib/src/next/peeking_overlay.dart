// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:meta/meta.dart';

import 'peek_model.dart';

const double _kStartOverlayTransitionHeight = 28.0;

/// Builds the child which floats vertically above this overlay.
typedef ChildAboveBuilder = Widget Function(
    BuildContext context, double overlayHeight);

/// A bottom aligned overlay which peeks up over the bottom.
class PeekingOverlay extends StatefulWidget {
  /// The amount the overlay should peek above the bottom of its parent when
  /// hiding.
  final double peekHeight;

  /// The height to allow vertical drags to open/close the overlay.
  final double dragHandleHeight;

  /// The widget to display within the overlay.
  final Widget? child;

  /// Called when the overlay is hidden.
  final VoidCallback? onHide;

  /// Called when the overlay is shown.
  final VoidCallback? onShow;

  /// Constructor.
  const PeekingOverlay({
    Key? key,
    this.peekHeight = _kStartOverlayTransitionHeight,
    this.dragHandleHeight = 48.0,
    this.onHide,
    this.onShow,
    this.child,
  }) : super(key: key);

  @override
  PeekingOverlayState createState() => new PeekingOverlayState();
}

/// A [TickingDoubleState] that changes its height to [minValue] via [hide] and\
/// [maxValue] via [show].
///
/// As the [value] increases above [minValue] [PeekingOverlay.child] will grow
/// up from the bottom.  The area not given to that [Widget] will gradually
/// darken.
///
/// The [createWidget] [Widget] will be clipped to [value] but will be given
/// [maxValue] to be laid out in.
class PeekingOverlayState extends TickingDoubleState<PeekingOverlay> {
  static const double _kSnapVelocityThreshold = 500.0;
  bool _hiding = true;
  bool? _peeking;

  @override
  void initState() {
    super.initState();
    maxValue = widget.peekHeight;
    _setPeeking(true);
  }

  @override
  void didUpdateWidget(PeekingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.peekHeight != widget.peekHeight) {
      minValue = (_peeking == true) ? widget.peekHeight : 0.0;
      if (_hiding) {
        setValue(minValue);
      } else {
        setValue(maxValue);
      }
    }
  }

  /// Hides the overlay.
  void hide() {
    widget.onHide?.call();
    _hiding = true;
    setValue(minValue);
  }

  /// Shows the overlay.
  void show() {
    widget.onShow?.call();
    _hiding = false;
    setValue(maxValue);
  }

  /// If [peeking] is true, the overlay will pop up itself over the bottom of
  /// its parent by the [PeekingOverlay.peekHeight].
  void _setPeeking(bool peeking) {
    if (peeking != (_peeking ?? false)) {
      _peeking = peeking;
      minValue = (_peeking == true) ? widget.peekHeight : 0.0;
      hide();
    }
  }

  /// Returns true if the overlay is currently hiding.
  bool get hiding => _hiding;

  /// Updates the overlay as if it was being dragged vertically.
  void onVerticalDragUpdate(DragUpdateDetails details) =>
      setValue(value - (details.primaryDelta ?? 0.0), force: true);

  /// Updates the overlay as if it was finished being dragged vertically.
  void onVerticalDragEnd(DragEndDetails details) =>
      snap(details.velocity.pixelsPerSecond.dy);

  /// Snaps the overlay open (showing) or closed (hiding) based on the vertical
  /// velocity occuring at the time a vertical drag finishes.
  void snap(double verticalVelocity) {
    if (verticalVelocity < -_kSnapVelocityThreshold) {
      show();
    } else if (verticalVelocity > _kSnapVelocityThreshold) {
      hide();
    } else if (value - minValue < maxValue - value) {
      hide();
    } else {
      show();
    }
  }

  @override
  Widget build(BuildContext context) => new Offstage(
        offstage: value == 0.0,
        child: new ScopedModelDescendant<PeekModel>(
          builder: (BuildContext context, Widget? child, PeekModel model) {
            _setPeeking(model.peek);
            return child ?? const SizedBox.shrink();
          },
          child: new Stack(
            fit: StackFit.expand,
            children: <Widget>[
              new Offstage(
                offstage: hiding,
                child: new Listener(
                  onPointerUp: (_) => hide(),
                  behavior: HitTestBehavior.opaque,
                ),
              ),
              new Positioned(
                left: 0.0,
                right: 0.0,
                bottom: -widget.peekHeight,
                height: value +
                    (math.min(widget.peekHeight, value) / widget.peekHeight) *
                        widget.peekHeight,
                child: new ScopedModelDescendant<SizeModel>(
                  builder: (_, Widget? child, SizeModel sizeModel) {
                    // Set maxHeight appropriately.
                    double targetMaxHeight = sizeModel.suggestionExpandedHeight;
                    if (maxValue != targetMaxHeight && targetMaxHeight != 0.0) {
                      maxValue = targetMaxHeight;
                      if (!hiding) {
                        show();
                      }
                    }

                    return new _HorizontalExpandingBox(
                      width: sizeModel.suggestionListWidth,
                      height: math.max(value, maxValue),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  child: new Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      widget.child ?? const SizedBox.shrink(),
                      new Positioned(
                        top: 0.0,
                        left: 0.0,
                        right: 0.0,
                        height: hiding
                            ? widget.peekHeight
                            : widget.dragHandleHeight,
                        child: new GestureDetector(
                          onVerticalDragUpdate: onVerticalDragUpdate,
                          onVerticalDragEnd: onVerticalDragEnd,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Uses the RK4 simulation of the [TickingDoubleState] to animate the width
/// of the suggestion box
class _HorizontalExpandingBox extends StatefulWidget {
  /// Height of the box
  final double height;

  /// Width of the box that will be animated with a RK4 simulation when changed
  final double width;

  final Widget child;

  /// Constructor
  const _HorizontalExpandingBox({
    required this.height,
    required this.width,
    required this.child,
  });

  @override
  _HorizontalExpandingBoxState createState() =>
      new _HorizontalExpandingBoxState();
}

class _HorizontalExpandingBoxState
    extends TickingDoubleState<_HorizontalExpandingBox> {
  @override
  void initState() {
    super.initState();
    maxValue = widget.width;
    minValue = 0.0;
    setValue(widget.width, force: true);
  }

  @override
  void didUpdateWidget(_HorizontalExpandingBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width) {
      maxValue = widget.width;
      setValue(widget.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      minWidth: value,
      maxWidth: value,
      minHeight: widget.height,
      maxHeight: widget.height,
      alignment: FractionalOffset.topCenter,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
