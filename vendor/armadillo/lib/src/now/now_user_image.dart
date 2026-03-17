// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/widgets.dart';

import 'context_model.dart';
import 'now_minimization_model.dart';
import 'quick_settings_progress_model.dart';

/// Displays the user image for now.
class NowUserImage extends StatelessWidget {
  /// Called when then image is tapped.
  final VoidCallback? onTap;

  /// Constructor.
  const NowUserImage({this.onTap});

  @override
  Widget build(BuildContext context) => new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: new ScopedModelDescendant<QuickSettingsProgressModel>(
          builder: (
            BuildContext context,
            Widget? child,
            QuickSettingsProgressModel quickSettingsProgressModel,
          ) =>
              new ScopedModelDescendant<NowMinimizationModel>(
            builder: (
              BuildContext context,
              Widget? child,
              NowMinimizationModel nowMinimizationModel,
            ) =>
                _buildUserImage(
              quickSettingsProgressModel,
              nowMinimizationModel,
              child,
            ),
            child: child!,
          ),
          child: _buildUser(),
        ),
      );

  Widget _buildUserImage(
    QuickSettingsProgressModel quickSettingsProgressModel,
    NowMinimizationModel nowMinimizationModel,
    Widget? child,
  ) =>
      new PhysicalModel(
        color: Colors.white,
        shape: BoxShape.circle,
        elevation: quickSettingsProgressModel.value *
            Elevations.nowUserQuickSettingsOpen,
        child: new AspectRatio(
          aspectRatio: 1.0,
          child: new Container(
            foregroundDecoration: new BoxDecoration(
              border: new Border.all(
                color: Colors.white,
                width: nowMinimizationModel.userImageBorderWidth,
              ),
              shape: BoxShape.circle,
            ),
            child: child,
          ),
        ),
      );

  /// Returns an avatar of the current user.
  Widget _buildUser() => new ScopedModelDescendant<ContextModel>(
        builder: (
          BuildContext context,
          Widget? child,
          ContextModel contextModel,
        ) {
          String avatarUrl = _getImageUrl(contextModel.userImageUrl) ?? '';
          String name = contextModel.userName ?? '';
          if (avatarUrl.isEmpty && name.isEmpty) {
            return const Offstage();
          }
          return avatarUrl.isNotEmpty
              ? new Alphatar.fromNameAndUrl(
                  avatarUrl: avatarUrl,
                  name: name,
                )
              : new Alphatar.fromName(
                  name: name,
                );
        },
      );

  String? _getImageUrl(String? userImageUrl) {
    if (userImageUrl == null) {
      return null;
    }
    Uri uri = Uri.parse(userImageUrl);
    if (uri.queryParameters['sz'] != null) {
      Map<String, dynamic> queryParameters = new Map<String, dynamic>.from(
        uri.queryParameters,
      );
      queryParameters['sz'] = '112';
      uri = uri.replace(queryParameters: queryParameters);
    }
    return uri.toString();
  }
}
