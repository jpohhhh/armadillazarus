// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'context_model.dart';
import 'important_info.dart';
import 'now_minimization_model.dart';
import 'now_user_image.dart';
import 'quick_settings_progress_model.dart';
import 'user_context_text.dart';

const TextStyle _kTextStyle = const TextStyle(
  fontSize: 10.0,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w300,
);

/// Displays the user and maximized quick settings text.
class NowUserAndMaximizedContext extends StatelessWidget {
  /// Called when the user's context text is tapped.
  final VoidCallback? onUserContextTapped;

  /// Called when user's time text is tapped.
  final VoidCallback? onUserTimeTapped;

  /// Called when the user image is tapped.
  final VoidCallback? onUserTapped;

  /// Called when the wifi info is tapped.
  final VoidCallback? onWifiInfoTapped;

  /// Constructor.
  const NowUserAndMaximizedContext({
    this.onUserContextTapped,
    this.onUserTimeTapped,
    this.onUserTapped,
    this.onWifiInfoTapped,
  });

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<NowMinimizationModel>(
        builder: (
          BuildContext context,
          Widget? child,
          NowMinimizationModel nowMinimizationModel,
        ) =>
            new Container(
          height: nowMinimizationModel.userImageDiameter,
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // User Context Text when maximized.
              new Expanded(
                child: _buildQuickSettingsText(
                  startingXOffset: -16.0,
                  slideInProgress:
                      nowMinimizationModel.maximizedTextSlideInProgress,
                  builder: (Color color) => new UserContextText(
                    textColor: color,
                    onUserContextTapped: onUserContextTapped,
                    onUserTimeTapped: onUserTimeTapped,
                  ),
                ),
              ),
              // User Profile image
              new NowUserImage(
                onTap: onUserTapped,
              ),
              // Important Information when maximized.
              new Expanded(
                child: new Stack(
                  children: <Widget>[
                    _buildUserDisplayName(),
                    _buildQuickSettingsText(
                      startingXOffset: 16.0,
                      slideInProgress:
                          nowMinimizationModel.maximizedTextSlideInProgress,
                      builder: (Color color) => new ImportantInfo(
                        textColor: color,
                        onWifiInfoTapped: onWifiInfoTapped,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildQuickSettingsText({
    required double startingXOffset,
    double slideInProgress = 1.0,
    required Widget Function(Color color) builder,
  }) =>
      new Opacity(
        opacity: slideInProgress,
        child: new ScopedModelDescendant<QuickSettingsProgressModel>(
          builder: (
            BuildContext context,
            Widget? child,
            QuickSettingsProgressModel quickSettingsProgressModel,
          ) =>
              new Transform(
            transform: new Matrix4.translationValues(
              lerpDouble(startingXOffset, 0.0, slideInProgress)!,
              lerpDouble(0.0, 32.0, quickSettingsProgressModel.value)!,
              0.0,
            ),
            child: builder(
              Color.lerp(
                Colors.white,
                Colors.grey[600],
                quickSettingsProgressModel.value,
              )!,
            ),
          ),
        ),
      );

  Widget _buildUserDisplayName() => new ScopedModelDescendant<ContextModel>(
        builder: (
          BuildContext context,
          Widget? child,
          ContextModel contextModel,
        ) =>
            new ScopedModelDescendant<QuickSettingsProgressModel>(
          builder: (
            BuildContext context,
            Widget? child,
            QuickSettingsProgressModel quickSettingsProgressModel,
          ) =>
              new Opacity(
            // Fade in as quick settings opens.
            opacity: quickSettingsProgressModel.value,
            child: new Transform(
              // Slide to the left slightly as we fade in.
              transform: new Matrix4.translationValues(
                lerpDouble(
                  24.0,
                  8.0,
                  quickSettingsProgressModel.value,
                )!,
                4.0,
                0.0,
              ),
              child: new Text(
                contextModel.userName ?? '',
                softWrap: false,
                overflow: TextOverflow.fade,
                style: _kTextStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      );
}
