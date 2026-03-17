// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

final Color _kPlaceholderColor = Colors.grey[300]!;

/// Renders a text placeholder meant for loading/scaffolding
class TextPlaceholder extends StatelessWidget {
  /// Constructor
  const TextPlaceholder({
    required this.style,
    this.width = 80.0,
  });

  /// Style of the text that this placeholder is used for
  final TextStyle style;

  /// Width that this placeholder should take up
  final double width;

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: new EdgeInsets.symmetric(
        vertical: (style.fontSize! * style.height! - style.fontSize!) / 2.0,
      ),
      color: _kPlaceholderColor,
      height: style.fontSize!,
      width: width,
    );
  }
}
