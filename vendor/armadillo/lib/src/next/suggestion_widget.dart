// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// ARMADILLAZARUS(parity): Original imported fidl_fuchsia_images and lib.proposal.dart.
// EncodedImage and readEncodedImage now live in suggestion.dart.

import 'suggestion.dart' as suggest;
import 'dart:typed_data';
import 'suggestion.dart' show EncodedImage, readEncodedImage;
import 'suggestion_layout.dart';

/// Gives each suggestion a slight rounded edge.
/// TODO(apwilson): We may want to animate this to zero when expanding the card
/// to fill the screen.
const double kSuggestionCornerRadius = 8.0;

/// The diameter of the person image.
const double _kPersonImageDiameter = 48.0;

/// Displays a [Suggestion].
class SuggestionWidget extends StatelessWidget {
  /// The suggestion to display.
  final suggest.Suggestion suggestion;

  /// Called with the suggestion is tapped.
  final VoidCallback? onSelected;

  /// If false, the widget will be invisible.
  final bool visible;

  /// If true, the widget has a shadow under it.
  final bool shadow;

  /// Constructor.
  const SuggestionWidget({
    Key? key,
    required this.suggestion,
    this.onSelected,
    this.visible = true,
    this.shadow = false,
  }) : super(key: key);

  bool get _hasImage =>
      (suggestion.image != null) || suggestion.icons.isNotEmpty;

  bool get _isCircular =>
      (suggestion.image != null &&
          suggestion.imageType == suggest.ImageType.person) ||
      (suggestion.image == null && suggestion.icons.isNotEmpty);

  suggest.ImageSide get _imageSide => suggestion.image != null &&
          suggestion.imageType == suggest.ImageType.person
      ? suggest.ImageSide.left
      : suggest.ImageSide.right;

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints boxConstraints) {
          suggestion.suggestionLayout.layout(
            boxConstraints.maxWidth,
            Directionality.of(context),
          );
          Widget image = _buildImage(
            context,
            suggestion.suggestionLayout.suggestionHeight,
          );
          Widget textAndIcons = _buildText(
            context,
            suggestion.suggestionLayout.suggestionText ??
                const SizedBox.shrink(),
          );

          List<Widget> rowChildren = _imageSide == suggest.ImageSide.left
              ? <Widget>[image, textAndIcons]
              : <Widget>[textAndIcons, image];

          return new Container(
            height: suggestion.suggestionLayout.suggestionHeight,
            width: suggestion.suggestionLayout.suggestionWidth,
            child: new Offstage(
              offstage: !visible,
              child: new PhysicalModel(
                color: Colors.white,
                borderRadius: new BorderRadius.circular(
                  kSuggestionCornerRadius,
                ),
                elevation: shadow ? Elevations.interruption : 0.0,
                child: new GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSelected,
                  child: new Row(children: rowChildren),
                ),
              ),
            ),
          );
        },
      );

  Widget _buildText(BuildContext context, Widget suggestionText) =>
      new Expanded(
        child: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new Padding(
            padding: new EdgeInsets.only(
              left: suggestion.suggestionLayout.leftTextPadding,
              right: suggestion.suggestionLayout.rightTextPadding,
            ),
            child: suggestionText,
          ),
        ),
      );

  Widget _buildImage(BuildContext context, double suggestionHeight) {
    if (!_hasImage) {
      return new Container(width: 0.0);
    } else {
      Widget image = _createImage(
        image:
            suggestion.image != null ? suggestion.image : suggestion.icons[0],
        fit: BoxFit.cover,
        alignment: FractionalOffset.center,
      );

      return new Container(
        width: kSuggestionImageWidth,
        child: _isCircular
            ? new Padding(
                padding: new EdgeInsets.symmetric(
                  vertical: (suggestionHeight - _kPersonImageDiameter) / 2.0,
                  horizontal:
                      (kSuggestionImageWidth - _kPersonImageDiameter) / 2.0,
                ),
                child: new SizedBox(
                  width: _kPersonImageDiameter,
                  height: _kPersonImageDiameter,
                  child: _imageSide == suggest.ImageSide.left
                      ? new ClipOval(
                          child: image,
                        )
                      : image,
                ),
              )
            : new ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: const Radius.circular(kSuggestionCornerRadius),
                  bottomRight: const Radius.circular(
                    kSuggestionCornerRadius,
                  ),
                ),
                child: new Container(
                  constraints: const BoxConstraints.expand(),
                  child: image,
                ),
              ),
      );
    }
  }

  Widget _createImage({
    EncodedImage? image,
    BoxFit fit = BoxFit.cover,
    FractionalOffset alignment = FractionalOffset.center,
  }) {
    final imageData = readEncodedImage(image);
    if (imageData != null) {
      return new Image.memory(imageData, fit: fit, alignment: alignment);
    }
    return new Container();
  }
}
