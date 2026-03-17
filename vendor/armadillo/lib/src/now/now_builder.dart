// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/recent.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'now.dart';
import 'now_minimization_model.dart';
import 'quick_settings.dart';

/// Builds now.
class NowBuilder {
  /// How far Now should raise when quick settings is activated inline.
  static const double kQuickSettingsHeightBump = 120.0;

  /// The simulation for the minimization to a bar.
  final NowMinimizationModel _nowMinimizationModel = new NowMinimizationModel();

  final GlobalKey<QuickSettingsOverlayState> _quickSettingsOverlayKey =
      new GlobalKey<QuickSettingsOverlayState>();

  VoidCallback? _onLogoutSelected;
  VoidCallback? _onUserContextTapped;
  ValueChanged<bool>? _onQuickSettingsOverlayChanged;

  /// Called when user requests to log out.
  set onLogoutSelected(VoidCallback onLogoutSelected) {
    _onLogoutSelected = onLogoutSelected;
  }

  /// Called when the user taps the user context.
  set onUserContextTapped(VoidCallback onUserContextTapped) {
    _onUserContextTapped = onUserContextTapped;
  }

  /// Called when the quick settings overlay is shown/hidden.
  set onQuickSettingsOverlayChanged(
      ValueChanged<bool> onQuickSettingsOverlayChanged) {
    _onQuickSettingsOverlayChanged = onQuickSettingsOverlayChanged;
  }

  /// Called when now is minimized.
  set onMinimize(VoidCallback onMinimize) {
    _nowMinimizationModel.onMinimize = onMinimize;
  }

  /// Called when now is maximized.
  set onMaximize(VoidCallback onMaximize) {
    _nowMinimizationModel.onMaximize = onMaximize;
  }

  /// Builds now.
  Widget build(
    BuildContext context, {
    VoidCallback? onMinimizedTap,
    VoidCallback? onQuickSettingsMaximized,
    GestureDragUpdateCallback? onBarVerticalDragUpdate,
    GestureDragEndCallback? onBarVerticalDragEnd,
    VoidCallback? onMinimizedContextTapped,
    required ValueNotifier<double> recentsScrollOffset,
  }) =>
      new ScopedModel<NowMinimizationModel>(
        model: _nowMinimizationModel,
        child: new Stack(
          children: <Widget>[
            new RepaintBoundary(
              child: new Now(
                quickSettingsHeightBump: kQuickSettingsHeightBump,
                onMinimizedTap: onMinimizedTap,
                onMinimizedLongPress: () =>
                    _quickSettingsOverlayKey.currentState?.show(),
                onQuickSettingsMaximized: onQuickSettingsMaximized,
                onBarVerticalDragUpdate: onBarVerticalDragUpdate,
                onBarVerticalDragEnd: onBarVerticalDragEnd,
                onLogoutSelected: _onLogoutSelected,
                onUserContextTapped: _onUserContextTapped,
                onMinimizedContextTapped: onMinimizedContextTapped,
                recentsScrollOffset: recentsScrollOffset,
              ),
            ),
            // Quick Settings Overlay.
            new QuickSettingsOverlay(
              key: _quickSettingsOverlayKey,
              onProgressChanged: (double progress) {
                if (progress == 0.0) {
                  _onQuickSettingsOverlayChanged?.call(false);
                } else {
                  _onQuickSettingsOverlayChanged?.call(true);
                }
              },
              onLogoutSelected: _onLogoutSelected,
            ),
          ],
        ),
      );

  /// Call when now should minimize.
  void minimize() {
    _nowMinimizationModel.minimize();
  }

  /// Call when now should maximize.
  void maximize() {
    _nowMinimizationModel.maximize();
  }
}
