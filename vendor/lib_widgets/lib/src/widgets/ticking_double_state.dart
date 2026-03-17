// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'rk4_spring_simulation.dart';
import 'ticking_state.dart';

const double _kSimulationTension = 450.0;
const double _kSimulationFriction = 50.0;
const RK4SpringDescription _kSimulationDesc = const RK4SpringDescription(
    tension: _kSimulationTension, friction: _kSimulationFriction);

/// A [TickingState] that simulates changes to a double as a RK4 spring.
abstract class TickingDoubleState<T extends StatefulWidget>
    extends TickingState<T> {
  /// The description of the spring simulation used to change the value of this
  /// [Widget].
  final RK4SpringDescription springDescription;

  // ARMADILLAZARUS(parity): was implicitly null in old Dart.
  // Original code null-checks before use, so nullable is correct.
  RK4SpringSimulation? _springSimulation;
  double _minValue = 0.0;
  double _maxValue = 0.0;

  /// Constructor.
  TickingDoubleState({this.springDescription = _kSimulationDesc});

  /// Returns the minimum value this [Widget] should have.
  double get minValue => _minValue;

  /// Sets the minimum value this [Widget] should have.
  set minValue(double minValue) {
    _minValue = minValue;
    if (value < _minValue) {
      setValue(_minValue);
    }
  }

  /// Returns the maximum value this [Widget] should have.
  double get maxValue => _maxValue;

  /// Sets the maximum value this [Widget] should have.
  set maxValue(double maxValue) {
    _maxValue = maxValue;
    if (value > _maxValue) {
      setValue(_maxValue);
    }
  }

  /// Sets the target value of this widget to [value].  This will trigger
  /// an animation from the current value to this new value unless [force]
  /// is set to true at which point the widget's value will jump directly to
  /// the new value.
  void setValue(double value, {bool force = false}) {
    double newValue = value.clamp(_minValue, _maxValue);
    if (force) {
      _springSimulation =
          new RK4SpringSimulation(initValue: newValue, desc: springDescription);
    } else {
      if (_springSimulation == null) {
        _springSimulation = new RK4SpringSimulation(
            initValue: newValue, desc: springDescription);
      } else {
        _springSimulation!.target = newValue;
      }
    }
    startTicking();
  }

  /// The current value the widget should be.
  double get value =>
      (_springSimulation == null || _springSimulation!.value < 0.0)
          ? 0.0
          : _springSimulation!.value;

  @override
  bool handleTick(double elapsedSeconds) {
    bool continueTicking = false;

    if (_springSimulation != null) {
      if (!_springSimulation!.isDone) {
        _springSimulation!.elapseTime(elapsedSeconds);
        if (!_springSimulation!.isDone) {
          continueTicking = true;
        }
      }
    }
    return continueTicking;
  }
}
