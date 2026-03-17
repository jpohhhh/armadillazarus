// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Handles focus progress for a StoryCluster.
class FocusModel extends SpringModel {
  /// Called when a story cluster begins focusing.
  VoidCallback? onStoryClusterFocusStarted;

  /// Called when a story cluster finishes focusing.
  VoidCallback? onStoryClusterFocusCompleted;

  /// Constructor.
  FocusModel({
    this.onStoryClusterFocusStarted,
    this.onStoryClusterFocusCompleted,
  }) : super(springDescription: _kSimulationDesc);

  bool get _isFocused => isDone && value == 1.0;

  @override
  void jump(double value) {
    bool wasFocused = _isFocused;
    super.jump(value);
    if (_isFocused && !wasFocused) {
      onStoryClusterFocusCompleted?.call();
    }
  }

  @override
  set target(double newTarget) {
    double currentTarget = target;
    super.target = newTarget;
    if (currentTarget != 1.0 && target == 1.0) {
      onStoryClusterFocusStarted?.call();
    }
  }

  @override
  bool handleTick(double elapsedSeconds) {
    bool wasFocused = _isFocused;
    bool result = super.handleTick(elapsedSeconds);
    if (_isFocused && !wasFocused) {
      onStoryClusterFocusCompleted?.call();
    }
    return result;
  }
}
