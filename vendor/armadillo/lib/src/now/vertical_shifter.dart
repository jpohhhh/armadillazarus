// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'quick_settings_progress_model.dart';

/// Shifts by [verticalShift] as [QuickSettingsProgressModel.value] goes to
/// 1.0.
class VerticalShifter extends StatelessWidget {
  /// The amount to shift [child] vertically by.
  final double verticalShift;

  /// The widget to shift vertically.
  final Widget child;

  /// Constructor.
  const VerticalShifter(
      {Key? key, required this.verticalShift, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<QuickSettingsProgressModel>(
        builder: (
          BuildContext context,
          Widget? child,
          QuickSettingsProgressModel quickSettingsProgressModel,
        ) {
          double shiftAmount = quickSettingsProgressModel.value * verticalShift;
          return new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new Positioned(
                left: 0.0,
                right: 0.0,
                top: -shiftAmount,
                bottom: shiftAmount,
                child: child ?? const SizedBox.shrink(),
              ),
            ],
          );
        },
        child: child,
      );
}
