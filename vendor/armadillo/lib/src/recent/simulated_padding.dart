// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Padding]'s fractional left padding and fractional right padding
/// with a spring simulation.
class SimulatedPadding extends StatelessWidget {
  /// The SimulatedPadding's state.
  final SimulatedPaddingModel model;

  /// The parent's width.
  final double width;

  /// The widget to apply padding to.
  final Widget child;

  /// Constructor.
  const SimulatedPadding(
      {required this.model, required this.width, required this.child});

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
        animation: model,
        builder: (BuildContext context, Widget? child) => new Padding(
          // ARMADILLAZARUS(parity): clamp final result to prevent spring overshoot
          padding: EdgeInsets.only(
            left: (width * model.left).clamp(0.0, double.infinity),
            right: (width * model.right).clamp(0.0, double.infinity),
          ),
          child: child,
        ),
        child: child,
      );
}

/// The state of the simulated padding.
class SimulatedPaddingModel extends TickingModel {
  /// The description of the spring to use for simulating transitions.
  final RK4SpringDescription springDescription;

  final RK4SpringSimulation _leftSimulation;
  final RK4SpringSimulation _rightSimulation;

  /// Constructor.
  SimulatedPaddingModel({
    this.springDescription = _kDefaultSimulationDesc,
    double fractionalLeftPadding = 0.0,
    double fractionalRightPadding = 0.0,
  })  : _leftSimulation = new RK4SpringSimulation(
          initValue: fractionalLeftPadding,
          desc: springDescription,
        ),
        _rightSimulation = new RK4SpringSimulation(
          initValue: fractionalRightPadding,
          desc: springDescription,
        );

  /// Gives new padding targets.
  void update({
    required double fractionalLeftPadding,
    required double fractionalRightPadding,
  }) {
    _leftSimulation.target = fractionalLeftPadding;
    _rightSimulation.target = fractionalRightPadding;
    startTicking();
  }

  /// The left fractional padding.
  double get left => _leftSimulation.value;

  /// The right fractional padding.
  double get right => _rightSimulation.value;

  @override
  bool handleTick(double elapsedSeconds) {
    _leftSimulation.elapseTime(elapsedSeconds);
    _rightSimulation.elapseTime(elapsedSeconds);
    return !_leftSimulation.isDone || !_rightSimulation.isDone;
  }
}
