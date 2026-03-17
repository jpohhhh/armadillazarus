// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:meta/meta.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

/// Animates a [FractionallySizedBox]'s height factor with a spring simulation.
class SimulatedFractionallySizedBox extends StatelessWidget {
  /// The state of the [SimulatedFractionallySizedBox].
  final SimulatedFractionallySizedBoxModel model;

  /// See [FractionallySizedBox.alignment].
  final FractionalOffset alignment;

  /// The widget to be sized by this box.
  final Widget child;

  /// Construuctor.
  const SimulatedFractionallySizedBox({
    required this.model,
    required this.alignment,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
        animation: model,
        builder: (BuildContext context, Widget? child) =>
            new FractionallySizedBox(
          alignment: alignment,
          heightFactor: model.value,
          widthFactor: 1.0,
          child: child,
        ),
        child: child,
      );
}

/// Tracks the simulation of the [SimulatedFractionallySizedBox]'s size.
class SimulatedFractionallySizedBoxModel extends SpringModel {
  /// Constructor.
  SimulatedFractionallySizedBoxModel()
      : super(springDescription: _kDefaultSimulationDesc) {
    jump(1.0);
  }
}
