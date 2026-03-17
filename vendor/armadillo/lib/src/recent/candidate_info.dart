// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'drag_direction.dart';
import 'panel_drag_target.dart';
import 'panel_drag_targets.dart';

const double _kDirectionMinSpeed = 100.0;
const Duration _kMinLockDuration = const Duration(milliseconds: 500);
const double _kMaxLockVelocityMagnitude = 500.0;

/// Once a drag target is chosen, this is the distance a draggable must travel
/// before new drag targets are considered.
const double _kStickyDistance = 40.0;

/// Returns a timestamp representing current time.
typedef TimestampEmitter = DateTime Function();

/// Manages the metadata associated with a dragged candidate in
/// [PanelDragTargets].
class CandidateInfo {
  /// Should be overridden in testing only.
  final TimestampEmitter timestampEmitter;

  /// The minimum duration a candidate should remain locked to its curren
  /// target before switching.
  final Duration minLockDuration;

  /// When a 'closest target' is chosen, the [Offset] of the candidate becomes
  /// the lock point for that target.  A new 'closest target' will not be chosen
  /// until the candidate travels the [_kStickyDistance] away from that lock
  /// point.
  Offset _lockPoint = Offset.zero;
  PanelDragTarget? _closestTarget;
  DateTime _timestamp = DateTime.now();
  VelocityTracker? _velocityTracker;
  DragDirection _lastDragDirection = DragDirection.none;
  Completer<bool>? _requestCompleter;
  Timer? _requestTimer;
  PanelDragTarget? _requestTarget;

  /// Constructor.
  CandidateInfo({
    required Offset initialLockPoint,
    this.timestampEmitter = _defaultTimestampEmitter,
    this.minLockDuration = _kMinLockDuration,
  }) : _lockPoint = initialLockPoint;

  /// The target the candidate has locked to.
  PanelDragTarget? get closestTarget => _closestTarget;

  /// Updates the candidate's velocity with [point].
  void updateVelocity(Offset point) {
    _velocityTracker ??= VelocityTracker.withKind(PointerDeviceKind.touch);
    _velocityTracker!.addPosition(
      new Duration(milliseconds: timestampEmitter().millisecondsSinceEpoch),
      point,
    );
  }

  /// Returns the candidate's velocity.
  Velocity get velocity => _velocityTracker?.getVelocity() ?? Velocity.zero;

  /// The candidate can lock to target closest to the candidate if the candidate:
  /// 1) is new, or
  /// 2) is old, and
  ///    a) the closest target to the candidate has changed,
  ///    b) we've moved past the sticky distance from the candidate's lock
  ///       point, and
  ///    c) the candidate's closest target hasn't changed recently.
  bool canLock(PanelDragTarget closestTarget, Offset storyClusterPoint) =>
      _hasNewPotentialTarget(closestTarget) &&
      _hasMovedPastThreshold(storyClusterPoint) &&
      _hasNotChangedRecently() &&
      _isNotMovingQuickly();

  /// Requests a lock.
  Future<bool> requestLock(
    PanelDragTarget closestTarget,
    Offset storyClusterPoint,
  ) {
    // If we're requesting and the target has changed cancel the request.
    if (_requestCompleter != null && _requestTarget != closestTarget) {
      dispose();
    }

    // If we still have an active request for this target, complete previous
    // request with false but maintain timer.
    if (_requestCompleter != null) {
      _requestCompleter!.complete(false);
      _requestCompleter = new Completer<bool>();
      return _requestCompleter!.future;
    }

    // If we can't lock to this target, complete with false immediately.
    if (!canLock(closestTarget, storyClusterPoint)) {
      return new Future<bool>.value(false);
    }

    // We can lock to this target start a timer.
    _requestCompleter = new Completer<bool>();
    _requestTarget = closestTarget;
    _requestTimer = new Timer(const Duration(milliseconds: 200), () {
      _requestCompleter?.complete(canLock(closestTarget, storyClusterPoint));
      _requestCompleter = null;
      _requestTimer = null;
    });

    return _requestCompleter!.future;
  }

  /// Cancels any existing timers.
  void dispose() {
    _requestCompleter?.complete(false);
    _requestCompleter = null;
    _requestTimer?.cancel();
    _requestTimer = null;
    _requestTarget = null;
  }

  /// Locks the candidate to [closestTarget] at the given [lockPoint].
  void lock(Offset lockPoint, PanelDragTarget closestTarget) {
    _timestamp = timestampEmitter();
    _lockPoint = lockPoint;
    _closestTarget = closestTarget;
  }

  /// Gets the direction the candidate is being dragged in.  This is based on
  /// the velocity candidate is being and has been dragged.
  DragDirection get dragDirection {
    DragDirection currentDragDirection = _dragDirectionFromVelocity;
    if (currentDragDirection != DragDirection.none) {
      _lastDragDirection = currentDragDirection;
    }
    return _lastDragDirection;
  }

  DragDirection get _dragDirectionFromVelocity {
    final Velocity? velocity = _velocityTracker?.getVelocity();
    if (velocity == null) {
      return DragDirection.none;
    } else if (velocity.pixelsPerSecond.dx.abs() >
        velocity.pixelsPerSecond.dy.abs()) {
      if (velocity.pixelsPerSecond.dx > _kDirectionMinSpeed) {
        return DragDirection.right;
      } else if (velocity.pixelsPerSecond.dx < -_kDirectionMinSpeed) {
        return DragDirection.left;
      } else {
        return DragDirection.none;
      }
    } else {
      if (velocity.pixelsPerSecond.dy > _kDirectionMinSpeed) {
        return DragDirection.down;
      } else if (velocity.pixelsPerSecond.dy < -_kDirectionMinSpeed) {
        return DragDirection.up;
      } else {
        return DragDirection.none;
      }
    }
  }

  bool _hasNewPotentialTarget(PanelDragTarget closestTarget) =>
      _closestTarget == null || (!_closestTarget!.isSameTarget(closestTarget));

  bool _hasMovedPastThreshold(Offset storyClusterPoint) =>
      (_lockPoint - storyClusterPoint).distance > _kStickyDistance;

  bool _hasNotChangedRecently() =>
      _timestamp == null ||
      timestampEmitter().subtract(minLockDuration).isAfter(_timestamp);

  bool _isNotMovingQuickly() =>
      velocity.pixelsPerSecond.distance <= _kMaxLockVelocityMagnitude;

  /// Turns a [CandidateInfo] into an [Offset] using the candidate's lock point.
  static Offset toPoint(CandidateInfo candidateInfo) =>
      candidateInfo._lockPoint;

  static DateTime _defaultTimestampEmitter() => new DateTime.now();
}
