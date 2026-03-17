// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:armadillo/common.dart';
import 'package:armadillo/now.dart';
import 'package:armadillo/recent.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

/// Builds the idle mode.
class IdleModeBuilder {
  /// Builds the idle mode.
  Widget build(BuildContext context) =>
      new Offstage(child: _buildIdle(context));

  Widget _buildIdle(BuildContext context) => new Center(
        child: new ScopedModelDescendant<ContextModel>(
          builder: (
            BuildContext context,
            Widget? child,
            ContextModel contextModel,
          ) =>
              new ScopedModelDescendant<SizeModel>(
            builder: (
              BuildContext context,
              Widget? child,
              SizeModel sizeModel,
            ) =>
                _buildTime(contextModel, sizeModel),
          ),
        ),
      );

  Widget _buildTime(ContextModel contextModel, SizeModel sizeModel) =>
      new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new RichText(
            text: new TextSpan(
              style: const TextStyle(
                fontWeight: FontWeight.w200,
                color: Colors.white,
              ),
              children: <TextSpan>[
                new TextSpan(
                  text: '${contextModel.timeOnly}',
                  style: new TextStyle(
                    fontSize: math.min(
                      sizeModel.screenSize.width / 6.0,
                      sizeModel.screenSize.height / 6.0,
                    ),
                    letterSpacing: 4.0,
                  ),
                ),
                new TextSpan(
                  text: '${contextModel.meridiem}',
                  style: new TextStyle(
                    fontSize: math.min(
                      sizeModel.screenSize.width / 28.0,
                      sizeModel.screenSize.height / 28.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          new Text(
            '${contextModel.dateOnly}',
            style: new TextStyle(
              fontSize: math.min(
                sizeModel.screenSize.width / 20.0,
                sizeModel.screenSize.height / 20.0,
              ),
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      );
}
