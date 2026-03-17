// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';

/// Spring description used by the minimization and quick settings reveal
/// simulations.
const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 600.0, friction: 50.0);

/// Fraction of the minimization animation which should be used for falling away
/// and sliding in of the user context and battery icon.
const double _kFallAwayDurationFraction = 0.35;

/// Tracks the progress of now minimizing.
class NowMinimizationModel extends SpringModel {
  VoidCallback? _onMinimize;
  VoidCallback? _onMaximize;

  /// Constructor.
  NowMinimizationModel() : super(springDescription: _kSimulationDesc);

  /// Called when now is minimized.
  set onMinimize(VoidCallback onMinimize) {
    _onMinimize = onMinimize;
  }

  /// Called when now is maximized.
  set onMaximize(VoidCallback onMaximize) {
    _onMaximize = onMaximize;
  }

  /// Minimizes Now to its bar state.
  void minimize() {
    if (!_minimizing) {
      target = 1.0;
      _onMinimize?.call();
    }
  }

  /// Maximizes Now to display the user and context text.
  void maximize() {
    if (_minimizing) {
      target = 0.0;
      _onMaximize?.call();
    }
  }

  /// The diameter the user image should be.
  double get userImageDiameter => lerpDouble(56.0, 12.0, value)!;

  /// The width of the border the user image should have.
  double get userImageBorderWidth => lerpDouble(2.0, 6.0, value)!;

  /// We slide in the context text and important information for the final
  /// portion of the maximization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get maximizedTextSlideInProgress {
    double fallAwayProgress = (1.0 -
            math.min(
              1.0,
              value / _kFallAwayDurationFraction,
            ))
        .clamp(0.0, 1.0);
    return fallAwayProgress < 0.8 ? 0.0 : ((fallAwayProgress - 0.8) / 0.2);
  }

  /// The distance to slide in minimized context text and important information.
  double get slideInDistance => lerpDouble(10.0, 0.0, slideInProgress)!;

  /// The opacity of minimized context text and important information.
  double get slideInOpacity => 0.6 * slideInProgress;

  /// We slide in the context text and important information for the final
  /// portion of the minimization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get slideInProgress => ((value - (1.0 - _kFallAwayDurationFraction)) /
          _kFallAwayDurationFraction)
      .clamp(0.0, 1.0);

  bool get _minimizing => target == 1.0;

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static NowMinimizationModel of(BuildContext context) =>
      new ModelFinder<NowMinimizationModel>().of(context);
}
