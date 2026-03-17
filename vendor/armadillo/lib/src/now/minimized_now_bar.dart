// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'context_model.dart';
import 'now_minimization_model.dart';
import 'power_model.dart';
import 'quick_settings_progress_model.dart';

/// Displays minimized Now bar.
class MinimizedNowBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => new ScopedModelDescendant<SizeModel>(
        builder: (
          BuildContext context,
          Widget? child,
          SizeModel sizeModel,
        ) =>
            _buildMinimizedUserContextTextAndImportantInformation(
          context,
          sizeModel,
        ),
      );

  Widget _buildMinimizedUserContextTextAndImportantInformation(
    BuildContext context,
    SizeModel sizeModel,
  ) =>
      new Align(
        alignment: FractionalOffset.bottomCenter,
        child: new ScopedModelDescendant<NowMinimizationModel>(
          builder: (
            BuildContext context,
            Widget? child,
            NowMinimizationModel nowMinimizationModel,
          ) =>
              new Container(
            height: sizeModel.minimizedNowHeight,
            padding: new EdgeInsets.symmetric(
              horizontal: 8.0 + nowMinimizationModel.slideInDistance,
            ),
            child: child,
          ),
          child: new RepaintBoundary(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildUserContextMinimized(),
                _buildImportantInfoMinimized(),
              ],
            ),
          ),
        ),
      );

  /// Returns a succinct representation of the user's current context.
  Widget _buildUserContextMinimized() => new Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: new ScopedModelDescendant<NowMinimizationModel>(
          builder: (
            BuildContext context,
            Widget? child,
            NowMinimizationModel nowMinimizationModel,
          ) =>
              new Opacity(
            opacity: nowMinimizationModel.slideInOpacity,
            child: child,
          ),
          child: new ScopedModelDescendant<ContextModel>(
            builder:
                (BuildContext context, Widget? child, ContextModel model) =>
                    new Text('${model.timeOnly}'),
          ),
        ),
      );

  /// Returns a succinct representation of the important information to the
  /// user.
  Widget _buildImportantInfoMinimized() =>
      new ScopedModelDescendant<PowerModel>(
        builder: (
          BuildContext context,
          Widget? child,
          PowerModel powerModel,
        ) =>
            !powerModel.hasBattery
                ? Nothing.widget
                : new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      new Padding(
                        padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                        child: new ScopedModelDescendant<NowMinimizationModel>(
                          builder: (
                            BuildContext context,
                            Widget? child,
                            NowMinimizationModel nowMinimizationModel,
                          ) =>
                              new Opacity(
                            opacity: nowMinimizationModel.slideInOpacity,
                            child: child,
                          ),
                          child: new Text(powerModel.batteryText),
                        ),
                      ),
                      new ScopedModelDescendant<NowMinimizationModel>(
                        builder: (
                          BuildContext context,
                          Widget? child,
                          NowMinimizationModel nowMinimizationModel,
                        ) =>
                            new Image.asset(
                          powerModel.batteryImageUrl,
                          color: Colors.white.withOpacity(
                            nowMinimizationModel.slideInOpacity,
                          ),
                          fit: BoxFit.cover,
                          height: 24.0,
                        ),
                      ),
                    ],
                  ),
      );
}
