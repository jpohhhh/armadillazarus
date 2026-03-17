// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:meta/meta.dart';

import 'armadillo_overlay.dart';

/// The time to wait before triggering a long press.
const Duration _kLongPressTimeout = const Duration(milliseconds: 300);

/// Exceeding this speed horizontally or vertically will not trigger acceptance
/// of a draggable in a drag target.
/// Pixels per second.
const double _kMaxAcceptanceSpeed = 1000.0;

/// Much of this code is borrowed from the Flutter framework's inplementation
/// of [Draggable] and [DragTarget].  What is different about this
/// implementation is the addition of each piece of data having an associated
/// [Offset] which indicates where it is when hovering
/// (passed in via [ArmadilloDragTargetWillAccept]) and when dropped (passed in
/// via [ArmadilloDragTargetAccept]).  We also use [ArmadilloOverlay] instead of
/// [Overlay] to display draggable drag feedback so the drag feedback can be
/// displayed in any part of the widget tree (and not just in an ancestor of the
/// draggable).
///
/// Other than keeping track of points for all candidates, the bulk of Flutter's
/// code remains intact.

/// Signature for building children of a [ArmadilloDragTarget].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [DragTarget] and that has passed [ArmadilloDragTarget.onWillAccept]. The
/// `rejectedData` argument contains the list of drag data that is hovering over
/// this [ArmadilloDragTarget] and that will not be accepted by the [ArmadilloDragTarget].
typedef ArmadilloDragTargetBuilder<T> = Widget Function(
  BuildContext context,
  Map<T, Offset> candidateData,
  Map<dynamic, Offset> rejectedData,
);

/// Signature for determining whether the given data will be accepted by a [ArmadilloDragTarget].
typedef ArmadilloDragTargetWillAccept<T> = bool Function(T data, Offset point);

/// Signature for causing a [ArmadilloDragTarget] to accept the given data.
typedef ArmadilloDragTargetAccept<T> = void Function(
  T data,
  Offset point,
  Velocity velocity,
);

/// Builds the feedback that should be shown while a
/// [ArmadilloLongPressDraggable] is being dragged.
/// [localDragStartPoint] indicates where the drag started in the draggable's
/// local coordinate space.
typedef FeedbackBuilder = Widget Function(
  Offset localDragStartPoint,
  Size initialSize,
);

/// Called when a drag starts.  The returned [Size] should be the size of the
/// dragged widget.
typedef OnDragStarted = Size Function();

/// A widget that can be dragged from to a [ArmadilloDragTarget] starting from long press.
///
/// When a draggable widget recognizes the start of a drag gesture, it displays
/// a widget built by [feedbackBuilder] that tracks the user's finger across the
/// screen. If the user lifts their finger while on top of a
/// [ArmadilloDragTarget], that target is given the opportunity to accept the
/// [data] carried by the draggble.
///
/// See also:
///
///  * [ArmadilloDragTarget]
class ArmadilloLongPressDraggable<T extends Object> extends StatefulWidget {
  /// Creates a widget that can be dragged starting from long press.
  ///
  /// The [child] and [feedbackBuilder] arguments must not be null.
  const ArmadilloLongPressDraggable({
    required this.overlayKey,
    required this.child,
    required this.feedbackBuilder,
    required this.data,
    Key? key,
    this.childWhenDragging,
    this.onDragStarted,
    this.onDragEnded,
    this.onDismiss,
  }) : super(key: key);

  // ARMADILLAZARUS(parity): original had these non-nullable but passed optionally.
  // Made nullable to preserve call-site behavior.

  /// The data that will be dropped by this draggable.
  final T data;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The widget to show instead of [child] when a drag is under way.
  ///
  /// If this is null, then [child] will be used instead (and so the
  /// drag source representation will change while a drag is under
  /// way).
  final Widget? childWhenDragging;

  /// The widget to show under the pointer when a drag is under way.
  final FeedbackBuilder feedbackBuilder;

  /// Called when a drag starts.  The bounds of the dragged widget should be
  /// returned by this callback.
  // ARMADILLAZARUS(parity): these were non-nullable in the original but
  // constructor call sites pass them optionally. Made nullable.
  final OnDragStarted? onDragStarted;

  /// Called when a drag ends.
  final VoidCallback? onDragEnded;

  /// Called when the draggable is dismissed.
  final VoidCallback? onDismiss;

  /// The key of the overlay the drag avatar will be built in.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  @override
  _DraggableState<T> createState() => new _DraggableState<T>();
}

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

class _DraggableState<T extends Object>
    extends State<ArmadilloLongPressDraggable<T>> {
  final GlobalKey<_DragAvatarWidgetState> _dragAvatarKey =
      new GlobalKey<_DragAvatarWidgetState>();
  final GlobalKey _nonDraggedChildKey = new GlobalKey();
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _createRecognizers();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showChild =
        (_activeCount == 0 || widget.childWhenDragging == null) &&
            (_dragAvatarKey.currentState?.isDone ?? true);
    return new Listener(
      key: _nonDraggedChildKey,
      behavior: HitTestBehavior.translucent,
      onPointerDown: _routePointer,
      child: showChild ? widget.child : widget.childWhenDragging,
    );
  }

  void _createRecognizers() {
    _recognizers
      ..add(
        new HorizontalMultiDragGestureRecognizer()..onStart = _startDrag,
      )
      ..add(
        new DelayedMultiDragGestureRecognizer(delay: _kLongPressTimeout)
          ..onStart = _startDrag,
      );
  }

  void _disposeRecognizers() {
    for (GestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
  }

  bool get _canDrag =>
      (_activeCount < 1) &&
      !(widget.overlayKey.currentState?.hasBuilders ?? false);

  void _routePointer(PointerEvent event) {
    if (_canDrag) {
      for (GestureRecognizer recognizer in _recognizers) {
        recognizer.addPointer(event as PointerDownEvent);
      }
    }
  }

  _DragAvatar<T>? _startDrag(Offset position) {
    if (!_canDrag) {
      return null;
    }

    setState(() {
      _activeCount += 1;
    });

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset dragStartPoint = box.globalToLocal(position);
    final Size? initialSize = widget.onDragStarted?.call();
    Widget builder(BuildContext context) => new _DragAvatarWidget(
          key: _dragAvatarKey,
          returnTargetKey: _nonDraggedChildKey,
          overlayKey: widget.overlayKey,
          initialPosition: position,
          dragStartPoint: dragStartPoint,
          initialSize: initialSize ?? Size.zero,
          feedbackBuilder: widget.feedbackBuilder,
          onDismiss: widget.onDismiss,
        );
    widget.overlayKey.currentState!.addBuilder(builder);

    _DragAvatar<T> dragAvatar = new _DragAvatar<T>(
      data: widget.data,
      onDragUpdate: (Offset position) =>
          _dragAvatarKey.currentState?.updatePosition(position),
      onDragEnd: (bool wasAccepted, Velocity velocity) {
        setState(() {
          _activeCount -= 1;
          if (!wasAccepted) {
            if (velocity.pixelsPerSecond.dx.abs() <= _kMaxAcceptanceSpeed) {
              _dragAvatarKey.currentState?.startReturnSimulation(
                velocity,
                () => setState(
                  () => widget.overlayKey.currentState!.removeBuilder(builder),
                ),
              );
            } else {
              _dragAvatarKey.currentState?.startExitSimulation(
                velocity,
                () => setState(
                  () => widget.overlayKey.currentState!.removeBuilder(builder),
                ),
              );
            }
          } else {
            widget.overlayKey.currentState!.removeBuilder(builder);
          }
        });
        widget.onDragEnded?.call();
      },
    )..position = position;

    return dragAvatar;
  }
}

/// This widget represents the Draggable's Avatar that follows the pointer
/// around the overlay.  It encapsulates all the state necessary to animate
/// the avatar back to the Draggable's original position when dragging first
/// started.  These include: [initialPosition], [dragStartPoint], and
/// [initialSize].
/// [overlayKey] is the key to the overlay this widget is a part of.  It's used
/// to properly position this widget to follow the pointer.
/// [feedbackBuilder] builds the widget that follows the pointer.
///  [returnTargetKey] is the key of the widget this widget will animate to
///  when it's dropped.
class _DragAvatarWidget extends StatefulWidget {
  final GlobalKey returnTargetKey;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final Offset initialPosition;
  final Offset dragStartPoint;
  final Size initialSize;
  final FeedbackBuilder feedbackBuilder;
  final VoidCallback? onDismiss;

  const _DragAvatarWidget({
    Key? key,
    required this.returnTargetKey,
    required this.overlayKey,
    required this.initialPosition,
    required this.dragStartPoint,
    required this.initialSize,
    required this.feedbackBuilder,
    this.onDismiss,
  }) : super(key: key);

  @override
  _DragAvatarWidgetState createState() => new _DragAvatarWidgetState();
}

class _DragAvatarWidgetState extends TickingState<_DragAvatarWidget> {
  // ARMADILLAZARUS(parity): was implicitly null. Made nullable.
  RK4SpringSimulation? _returnSimulation;
  VoidCallback? _onReturnSimulationDone;
  Offset _position = Offset.zero;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    RenderBox overlayBox =
        widget.overlayKey.currentContext!.findRenderObject()! as RenderBox;
    Offset overlayTopLeft = overlayBox.localToGlobal(Offset.zero);
    Offset localOffset = _position - widget.dragStartPoint;
    double left = localOffset.dx - overlayTopLeft.dx;
    double top = localOffset.dy - overlayTopLeft.dy;

    double returnProgress = _returnSimulation?.value ?? 0.0;
    if (returnProgress > 0.0) {
      final RenderBox returnTargetBox = widget.returnTargetKey.currentContext!
          .findRenderObject()! as RenderBox;
      final Offset returnTargetTopLeft = returnTargetBox.localToGlobal(
        Offset.zero,
      );
      left = lerpDouble(
        left,
        returnTargetTopLeft.dx - overlayTopLeft.dx,
        returnProgress,
      )!;
      top = lerpDouble(
        top,
        returnTargetTopLeft.dy - overlayTopLeft.dy,
        returnProgress,
      )!;
    }
    return new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        new Positioned(
          left: left,
          top: top,
          child: new IgnorePointer(
            child: widget.feedbackBuilder(
              widget.dragStartPoint,
              widget.initialSize,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool handleTick(double elapsedSeconds) {
    _returnSimulation?.elapseTime(elapsedSeconds);
    if (_returnSimulation?.isDone ?? false) {
      _onReturnSimulationDone?.call();
    }
    return !isDone;
  }

  void updatePosition(Offset position) => setState(() {
        _position = position;
      });

  bool get isDone => _returnSimulation?.isDone ?? true;

  void startReturnSimulation(
    Velocity velocity,
    VoidCallback onReturnSimulationDone,
  ) {
    _returnSimulation = new RK4SpringSimulation(
      initValue: 0.0,
      desc: _kDefaultSimulationDesc,
    )..target = 1.0;
    startTicking();
    _onReturnSimulationDone = onReturnSimulationDone;
  }

  void startExitSimulation(
    Velocity velocity,
    VoidCallback onExitSimulationDone,
  ) {
    onExitSimulationDone.call();
    widget.onDismiss?.call();
  }
}

/// A widget that receives data when a [ArmadilloLongPressDraggable] widget is dropped.
///
/// When a draggable is dragged on top of a drag target, the drag target is
/// asked whether it will accept the data the draggable is carrying. If the user
/// does drop the draggable on top of the drag target (and the drag target has
/// indicated that it will accept the draggable's data), then the drag target is
/// asked to accept the draggable's data.
///
/// See also:
///
///  * [ArmadilloLongPressDraggable]
class ArmadilloDragTarget<T extends Object> extends StatefulWidget {
  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final ArmadilloDragTargetBuilder<T> builder;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  final ArmadilloDragTargetWillAccept<T>? onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  final ArmadilloDragTargetAccept<T>? onAccept;

  /// Creates a widget that receives drags.
  ///
  /// The [builder] argument must not be null.
  const ArmadilloDragTarget({
    required this.builder,
    Key? key,
    this.onWillAccept,
    this.onAccept,
  })  : assert(builder != null),
        super(key: key);

  @override
  _DragTargetState<T> createState() => new _DragTargetState<T>();
}

class _DragTargetState<T extends Object> extends State<ArmadilloDragTarget<T>> {
  final Map<T, Offset> _candidateData = <T, Offset>{};
  final Map<dynamic, Offset> _rejectedData = <Object, Offset>{};

  bool didEnter(Object data, Offset localPosition) {
    assert(_candidateData[data] == null);
    assert(_rejectedData[data] == null);
    if (data is T && (widget.onWillAccept?.call(data, localPosition) ?? true)) {
      setState(() {
        _candidateData[data] = localPosition;
      });
      return true;
    }
    setState(() {
      _rejectedData[data] = localPosition;
    });
    return false;
  }

  void updatePosition(Object data, Offset localPosition) {
    if (data is! T) return;
    setState(() {
      if (_candidateData[data] != null) {
        _candidateData[data] = localPosition;
      }
      if (_rejectedData[data] != null) {
        _rejectedData[data] = localPosition;
      }
    });
  }

  void didLeave(Object data) {
    assert(_candidateData[data] != null || _rejectedData[data] != null);
    if (!mounted) {
      return;
    }
    setState(() {
      _candidateData.remove(data);
      _rejectedData.remove(data);
    });
  }

  void didDrop(Object data, Velocity velocity) {
    assert(_candidateData[data] != null);
    if (mounted) {
      Offset point = _candidateData[data]!;
      setState(() {
        _candidateData.remove(data);
        _rejectedData.remove(data);
      });
      if (data is T) widget.onAccept?.call(data, point, velocity);
    }
  }

  @override
  Widget build(BuildContext context) => new MetaData(
        metaData: this,
        behavior: HitTestBehavior.translucent,
        child: widget.builder(context, _candidateData, _rejectedData),
      );
}

enum _DragEndKind { dropped, canceled }

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away, or maybe even if the Draggable that created goes away.
// This will probably need to be changed once we have more experience with using
// this widget.
class _DragAvatar<T extends Object> extends Drag {
  final T data;
  final ValueChanged<Offset> onDragUpdate;
  final void Function(bool wasAccepted, Velocity velocity) onDragEnd;
  final List<_DragTargetState<T>> _activeTargets = <_DragTargetState<T>>[];
  final List<_DragTargetState<T>> _enteredTargets = <_DragTargetState<T>>[];

  Offset _position = Offset.zero;

  _DragAvatar(
      {required this.data,
      required this.onDragUpdate,
      required this.onDragEnd});

  set position(Offset newPosition) {
    _position = newPosition;
    _updateDrag(newPosition);
  }

  // Drag API
  @override
  void update(DragUpdateDetails details) {
    position = _position + details.delta;
  }

  @override
  void end(DragEndDetails details) => _finishDrag(
        _DragEndKind.dropped,
        details.velocity,
      );

  @override
  void cancel() => _finishDrag(_DragEndKind.canceled, Velocity.zero);

  void _updateDrag(Offset globalPosition) {
    onDragUpdate?.call(globalPosition);

    Iterable<_DragTargetState<T>> targets = _getDragTargets(globalPosition);

    // If everything's the same, bail early.
    if (!_match(targets, _enteredTargets)) {
      // Leave old targets.
      _leaveAllEntered();
      _enteredTargets.addAll(targets);

      // Enter new targets.
      _activeTargets
        ..clear()
        ..addAll(
          targets.where(
            (_DragTargetState<T> target) => target.didEnter(
              data,
              _globalToLocal(target, globalPosition),
            ),
          ),
        );
    }

    // Update positions
    for (_DragTargetState<T> target in _enteredTargets) {
      _updatePosition(target, globalPosition);
    }
  }

  Offset _globalToLocal(_DragTargetState<T> target, Offset globalPosition) {
    RenderBox box = target.context.findRenderObject()! as RenderBox;
    return box.globalToLocal(globalPosition);
  }

  void _updatePosition(_DragTargetState<T> target, Offset globalPosition) =>
      target.updatePosition(data, _globalToLocal(target, globalPosition));

  Iterable<_DragTargetState<T>> _getDragTargets(Offset globalPosition) sync* {
    HitTestResult result = new HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition);

    // Look for the RenderBoxes that corresponds to the hit target (the hit target
    // widgets build RenderMetaData boxes for us for this purpose).
    for (HitTestEntry entry in result.path) {
      if (entry.target is RenderMetaData) {
        // ARMADILLAZARUS(parity): entry.target is now HitTestTarget, not RenderMetaData
        RenderMetaData renderMetaData = entry.target as RenderMetaData;
        if (renderMetaData.metaData is _DragTargetState<T>) {
          yield renderMetaData.metaData as _DragTargetState<T>;
        }
      }
    }
  }

  bool _match(Iterable<dynamic> a, Iterable<dynamic> b) {
    bool listsMatch = false;
    if (a.length == b.length) {
      listsMatch = true;
      Iterator<dynamic> aIterator = a.iterator;
      Iterator<dynamic> bIterator = b.iterator;
      for (int i = 0; i < b.length; i += 1) {
        aIterator.moveNext();
        bIterator.moveNext();
        if (aIterator.current != bIterator.current) {
          listsMatch = false;
          break;
        }
      }
    }
    return listsMatch;
  }

  void _leaveAllEntered() {
    _enteredTargets
      ..forEach((_DragTargetState<T> target) => target.didLeave(data))
      ..clear();
  }

  void _finishDrag(_DragEndKind endKind, Velocity velocity) {
    bool wasAccepted = false;
    if (velocity.pixelsPerSecond.dx.abs() <= _kMaxAcceptanceSpeed &&
        velocity.pixelsPerSecond.dy.abs() <= _kMaxAcceptanceSpeed) {
      if (endKind == _DragEndKind.dropped && _activeTargets.isNotEmpty) {
        for (_DragTargetState<T> activeTarget in _activeTargets) {
          activeTarget.didDrop(data, velocity);
          _enteredTargets.remove(activeTarget);
        }
        wasAccepted = true;
      }
    }
    _leaveAllEntered();
    _activeTargets.clear();
    // TODO(ianh): consider passing _entry as well so the client can perform an animation.
    onDragEnd?.call(wasAccepted, velocity);
  }
}
