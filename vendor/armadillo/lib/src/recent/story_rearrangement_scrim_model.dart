// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:meta/meta.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Handles the story rearrangement transition progress.
class StoryRearrangementScrimModel extends SpringModel {
  /// Constructor.
  StoryRearrangementScrimModel() : super(springDescription: _kSimulationDesc);

  /// Starts the simulation of this [TickingModel].  If [isAcceptable] is true
  /// the opacity will be animated to non-transparent otherwise it will be
  /// animated to fully transparent.
  void onDragAcceptableStateChanged({required bool isAcceptable}) {
    target = isAcceptable ? 1.0 : 0.0;
    startTicking();
  }
}
