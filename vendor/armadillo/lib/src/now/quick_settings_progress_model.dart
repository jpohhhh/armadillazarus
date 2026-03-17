// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Spring description used by the minimization and quick settings reveal
/// simulations.
const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 600.0, friction: 50.0);

/// Fraction of the quick settings animation which should be used for fading in
/// the quick settings.
const double _kFadeInDurationFraction = 0.35;

/// Keeps track of quick settings opening progress.
// ARMADILLAZARUS(parity): was TracingSpringModel which added Cobalt tracing.
// Changed to SpringModel since Cobalt is Fuchsia-only.
class QuickSettingsProgressModel extends SpringModel {
  /// Constructor.
  QuickSettingsProgressModel() : super(springDescription: _kSimulationDesc);

  /// Showing or heading toward showing.
  bool get showing => target == 1.0;

  /// Shows quick settings.
  void show() {
    target = 1.0;
  }

  /// Hides quick settings.
  void hide() {
    target = 0.0;
  }

  /// The border radius of quick settings background.
  double get backgroundBorderRadius => lerpDouble(50.0, 4.0, value)!;

  /// We fade in the quick settings for the final portion of the
  /// quick settings animation as determined by [_kFadeInDurationFraction].
  double get fadeInProgress =>
      ((value - (1.0 - _kFadeInDurationFraction)) / _kFadeInDurationFraction)
          .clamp(0.0, 1.0);

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static QuickSettingsProgressModel of(BuildContext context) =>
      new ModelFinder<QuickSettingsProgressModel>()
          .of(context, rebuildOnChange: true);
}
