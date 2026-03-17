// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Function that returns a stylized widget with the specified text and
/// color.
typedef TextBuilder = Widget Function(
    BuildContext context, String text, Color color);

/// Text overlaid over another copy of text with shadow color.
class ShadowedText extends StatelessWidget {
  /// Function that returns the text widget
  final TextBuilder textBuilder;

  /// Text to display
  final String text;

  /// Shadow color
  final Color shadowColor;

  /// Text color
  final Color textColor;

  /// Constructor
  const ShadowedText({
    required this.textBuilder,
    required this.text,
    required this.shadowColor,
    required this.textColor,
  })  : assert(textBuilder != null),
        assert(text != null),
        assert(shadowColor != null),
        assert(textColor != null);

  @override
  Widget build(BuildContext context) {
    return new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        new Transform(
          transform: new Matrix4.translationValues(2.0, 2.0, 0.0),
          child: textBuilder(context, text, shadowColor),
        ),
        textBuilder(context, text, textColor),
      ],
    );
  }
}
