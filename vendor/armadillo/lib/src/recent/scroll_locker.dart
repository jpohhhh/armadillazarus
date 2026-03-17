// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

/// Locks and unlocks scrolling in its [child] and its descendants.
class ScrollLocker extends StatelessWidget {
  /// Holds the state for the ScrollLocker.
  final ScrollLockerModel model;

  /// The Widget whose scrolling will be locked.
  final Widget child;

  /// Constructor.
  const ScrollLocker({required this.model, required this.child});

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
        animation: model,
        builder: (BuildContext context, Widget? child) =>
            new ScrollConfiguration(
          behavior: model.scrollBehavior,
          child: child!,
        ),
        child: child,
      );
}

/// The [State] of [ScrollLocker].
class ScrollLockerModel extends Model {
  /// When true, list scrolling is disabled.
  bool _lockScrolling = false;

  /// Locks the scrolling of [ScrollLocker.child].
  void lock() {
    if (!_lockScrolling) {
      _lockScrolling = true;
      notifyListeners();
    }
  }

  /// Unlocks the scrolling of [ScrollLocker.child].
  void unlock() {
    if (_lockScrolling) {
      _lockScrolling = false;
      notifyListeners();
    }
  }

  /// The current scroll behavior.
  ScrollBehavior get scrollBehavior => new _LockingScrollBehavior(
        lock: _lockScrolling,
      );
}

class _LockingScrollBehavior extends ScrollBehavior {
  final bool lock;
  const _LockingScrollBehavior({this.lock = false});

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => lock
      ? const _LockedScrollPhysics(parent: const BouncingScrollPhysics())
      : const BouncingScrollPhysics();

  @override
  bool shouldNotify(_LockingScrollBehavior old) => lock != old.lock;
}

class _LockedScrollPhysics extends ScrollPhysics {
  const _LockedScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _LockedScrollPhysics applyTo(ScrollPhysics? parent) =>
      new _LockedScrollPhysics(parent: parent);

  @override
  Simulation createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // ARMADILLAZARUS(parity): original returned null; modern Flutter requires non-null
    return super.createBallisticSimulation(position, velocity) ??
        BouncingScrollSimulation(
            position: 0,
            velocity: 0,
            leadingExtent: 0,
            trailingExtent: 0,
            spring: SpringDescription(mass: 1, stiffness: 1, damping: 1));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) => 0.0;
}
