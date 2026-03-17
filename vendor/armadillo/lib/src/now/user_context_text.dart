// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'context_model.dart';

const TextStyle _kTimeTextStyle = const TextStyle(
  color: Colors.white,
  fontSize: 36.0,
  letterSpacing: 4.0,
  fontWeight: FontWeight.w300,
);

const TextStyle _kDateTextStyle = const TextStyle(
  color: Colors.white,
  fontSize: 12.0,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w300,
);

const TextStyle _kLocationTextStyle = const TextStyle(
  color: Colors.white,
  fontSize: 12.0,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w100,
);

const double _kWidthThreshold = 300.0;
const double _kTimeRightMargin = 8.0;
const double _kYInsetFudgeFactor = 6.0;
const double _kEdgeSpacing = 16.0;
const double _kUserSpacing = 32.0;
const double _kTextVerticalGap = 4.0;

/// Displays the time, date, and location context for the user.
class UserContextText extends StatelessWidget {
  /// The color the text in this widget will have.
  final Color textColor;

  /// Callback when user taps context
  final VoidCallback? onUserContextTapped;

  /// Callback when user taps time.
  final VoidCallback? onUserTimeTapped;

  /// Constructor.
  const UserContextText({
    Key? key,
    this.textColor = Colors.white,
    this.onUserContextTapped,
    this.onUserTimeTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => new ScopedModelDescendant<ContextModel>(
        builder: (BuildContext context, Widget? child, ContextModel model) =>
            new LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
          bool tight = constraints.maxWidth <= _kWidthThreshold;
          List<LayoutId> children = <LayoutId>[
            new LayoutId(
              id: _UserContextLayoutDelegateParts.location,
              child: _getGestureDetector(
                  new Text(
                    model.contextualLocation.toUpperCase(),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: _kLocationTextStyle.copyWith(
                      color: textColor,
                      fontSize: tight ? 10.0 : 12.0,
                    ),
                  ),
                  onUserContextTapped ?? () {}),
            ),
          ];
          if (tight) {
            children.add(
              new LayoutId(
                id: _UserContextLayoutDelegateParts.time,
                child: _getGestureDetector(
                    new Text(
                      model.timeOnly,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: _kDateTextStyle.copyWith(
                        color: textColor,
                        fontSize: 10.0,
                      ),
                    ),
                    onUserTimeTapped ?? () {}),
              ),
            );
          } else {
            children.addAll(<LayoutId>[
              new LayoutId(
                id: _UserContextLayoutDelegateParts.time,
                child: _getGestureDetector(
                    new Text(
                      model.timeOnly,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: _kTimeTextStyle.copyWith(color: textColor),
                    ),
                    onUserTimeTapped ?? () {}),
              ),
              new LayoutId(
                id: _UserContextLayoutDelegateParts.date,
                child: _getGestureDetector(
                    new Text(
                      model.dateOnly,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: _kDateTextStyle.copyWith(color: textColor),
                    ),
                    onUserContextTapped ?? () {}),
              ),
            ]);
          }
          return new CustomMultiChildLayout(
            delegate: new _UserContextLayoutDelegate(
              time: model.timeOnly,
              date: (constraints.maxWidth > _kWidthThreshold)
                  ? model.dateOnly
                  : null,
              location: model.contextualLocation.toUpperCase(),
            ),
            children: children,
          );
        }),
      );
}

Widget _getGestureDetector(Widget widget, VoidCallback tapCallback) {
  return new GestureDetector(
    child: widget,
    onTap: tapCallback,
    behavior: HitTestBehavior.opaque,
  );
}

enum _UserContextLayoutDelegateParts {
  time,
  date,
  location,
}

class _UserContextLayoutDelegate extends MultiChildLayoutDelegate {
  final String time;
  final String? date;
  final String location;

  _UserContextLayoutDelegate(
      {required this.time, this.date, required this.location});

  @override
  void performLayout(Size size) {
    // Lay out children.
    if (hasChild(_UserContextLayoutDelegateParts.date)) {
      Size timeSize = layoutChild(
        _UserContextLayoutDelegateParts.time,
        new BoxConstraints.loose(size),
      );
      Size dateSize = layoutChild(
        _UserContextLayoutDelegateParts.date,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: timeSize.width + _kTimeRightMargin + _kUserSpacing,
            top: timeSize.height / 2.0,
          ),
        ),
      );
      Size locationSize = layoutChild(
        _UserContextLayoutDelegateParts.location,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: timeSize.width + _kTimeRightMargin + _kUserSpacing,
            top: timeSize.height / 2.0,
          ),
        ),
      );

      double yInset = (size.height - timeSize.height) / 2.0;
      double timeRight = math.max(dateSize.width, locationSize.width) +
          _kTimeRightMargin +
          _kUserSpacing;

      // Position children.
      positionChild(
        _UserContextLayoutDelegateParts.time,
        new Offset(size.width - timeRight - timeSize.width, yInset),
      );
      positionChild(
        _UserContextLayoutDelegateParts.date,
        new Offset(
          size.width - timeRight + _kTimeRightMargin,
          yInset + _kYInsetFudgeFactor,
        ),
      );
      positionChild(
        _UserContextLayoutDelegateParts.location,
        new Offset(
          size.width - timeRight + _kTimeRightMargin,
          size.height - locationSize.height - yInset - _kYInsetFudgeFactor,
        ),
      );
    } else {
      Size timeSize = layoutChild(
        _UserContextLayoutDelegateParts.time,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: _kEdgeSpacing + _kUserSpacing / 2.0,
            top: size.height / 2.0,
          ),
        ),
      );
      Size locationSize = layoutChild(
        _UserContextLayoutDelegateParts.location,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: _kEdgeSpacing + _kUserSpacing / 2.0,
            top: size.height / 2.0,
          ),
        ),
      );
      double yInset = (size.height -
              timeSize.height -
              locationSize.height -
              _kTextVerticalGap) /
          2.0;

      // Position children.
      positionChild(
        _UserContextLayoutDelegateParts.time,
        new Offset(_kEdgeSpacing, yInset),
      );
      positionChild(
        _UserContextLayoutDelegateParts.location,
        new Offset(_kEdgeSpacing, size.height - yInset - locationSize.height),
      );
    }
  }

  @override
  bool shouldRelayout(_UserContextLayoutDelegate oldDelegate) =>
      time != oldDelegate.time ||
      date != oldDelegate.date ||
      location != oldDelegate.location;
}
