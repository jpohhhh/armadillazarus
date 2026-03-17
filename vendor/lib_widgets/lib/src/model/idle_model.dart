// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../widgets/rk4_spring_simulation.dart';
import 'spring_model.dart';

export 'model.dart' show ScopedModel, Model, ScopedModelDescendant;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 250.0, friction: 50.0);
const Duration _kIdleModeTimeout = const Duration(seconds: 600);

/// Handles transitioning into Idle mode.
class IdleModel extends SpringModel {
  Timer? _userInteractionTimer;
  bool _isIdle = false;

  /// The time to wait before triggering idle mode due to user inaction.
  Duration _timeout;

  /// Constructor.
  IdleModel({Duration timeout = _kIdleModeTimeout})
      : _timeout = timeout,
        super(springDescription: _kSimulationDesc) {
    this.timeout = timeout;
  }

  /// Sets a new timeout to wait before entering idle mode due to user inaction.
  set timeout(Duration newTimeout) {
    _timeout = newTimeout;
    _userInteractionTimer?.cancel();
    _userInteractionTimer = new Timer(
      _timeout,
      enterIdleMode,
    );
  }

  /// Adjusts idle mode based on the user interaction.
  void onUserInteraction() {
    leaveIdleMode();
    _userInteractionTimer?.cancel();
    _userInteractionTimer = new Timer(
      _timeout,
      enterIdleMode,
    );
  }

  /// Enters idle mode.
  void enterIdleMode() {
    target = 1.0;
    if (!_isIdle) {
      _isIdle = true;
      notifyListeners();
    }
  }

  /// Leaves idle mode.
  void leaveIdleMode() {
    target = 0.0;
    if (_isIdle) {
      _isIdle = false;
      notifyListeners();
    }
  }

  /// Returns true if we are in idle mode.
  bool get isIdle => _isIdle;
}
