// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// The various device form factors
enum FormFactor {
  /// The typical tablet/laptop screen size
  tablet,

  /// Phone in landscape mode
  phoneLandscape,

  /// Phone in portrait mode
  phonePortrait,
}

/// Target widths for the suggesiton section at different screen sizes.
const double _kTargetLargeSuggestionWidth = 736.0;
const double _kTargetSmallSuggestionWidth = 424.0;
const double _kSuggestionMinPadding = 40.0;

/// The height offset of Now when maximized in relation to the current peek
/// height of the suggestion list.
const double _kMaximizedNowHeightOffset = 220.0;

/// The height of the ask input section that is in the suggestion list
const double _kAskHeightLarge = 72.0;
const double _kAskHeightSmall = 56.0;

/// Peek height of the suggestion list for various form factors
const Map<FormFactor, double> _kSuggestionPeekHeight =
    const <FormFactor, double>{
  FormFactor.tablet: 220.0,
  FormFactor.phonePortrait: 140.0,
  FormFactor.phoneLandscape: 80.0,
};

/// The [SizeModel] tracks various global sizes that are required for rendering
/// the various parts of Armadillo.
///
/// The sizes that are tracked:
/// * ScreenSize: The size allocated to Armadillo.
/// * MinimizedNowHeight: The height of the minimized now bar which is based on
///   the total ScreenSize.
///
/// The [SizeModel] allows these values to be passed down the widget tree by
/// using a [ScopedModel] to retrieve the model.
class SizeModel extends Model {
  /// The height of the story bar when maximized.
  static const double kStoryBarMaximizedHeight = 24.0;

  /// The height of the story bar when minimized.
  static const double kStoryBarMinimizedHeight = 4.0;

  Size _screenSize = Size.zero;
  double _suggestionListWidth = 0.0;
  double _suggestionWidth = 0.0;
  double _interruptionLeftMargin = 0.0;
  FormFactor _formFactor = FormFactor.tablet;

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static SizeModel of(BuildContext context) =>
      new ModelFinder<SizeModel>().of(context);

  /// Gets the size of the entire space allocated to Armadillo
  Size get screenSize => _screenSize;

  /// Sets the screen size
  set screenSize(Size size) {
    if (size != _screenSize) {
      _screenSize = size;

      // How sizing of the suggestion section works:
      // 1. Try to accommodate the large target width with mininum padding
      // 2. Try to accomodate the small target width with mininum padding
      // 3. Stretch to the full width of the screen
      bool stretchToFullWidth = false;
      if (_screenSize.width >=
          _kTargetLargeSuggestionWidth + 2 * _kSuggestionMinPadding) {
        _suggestionListWidth = _kTargetLargeSuggestionWidth;
      } else if (_screenSize.width >
          _kTargetSmallSuggestionWidth + 2 * _kSuggestionMinPadding) {
        _suggestionListWidth = _kTargetSmallSuggestionWidth;
      } else {
        _suggestionListWidth = _screenSize.width;
        stretchToFullWidth = true;
      }

      _suggestionWidth = math.min(
        296.0,
        _suggestionListWidth - 32.0,
      );

      _interruptionLeftMargin = stretchToFullWidth
          ? (_suggestionListWidth - _suggestionWidth) / 2.0
          : 16.0;

      // Determine the form factor of the device.
      // Right now, this is very basic and only works with the current
      // "baked-in" device sizes of Armadillo.
      //
      // Eventually this should be more generic but we would need to also
      // know the physical size of the screen as well as the resolution.
      // https://fuchsia.atlassian.net/browse/SY-280
      if (size.height > 640.0) {
        _formFactor = FormFactor.tablet;
      } else if (size.height > 360.0) {
        _formFactor = FormFactor.phonePortrait;
      } else {
        _formFactor = FormFactor.phoneLandscape;
      }

      notifyListeners();
    }
  }

  /// Gets the size of a focused story.
  ///
  /// The story size is the screen size minus the minimized now bar height
  Size get storySize => new Size(
        _screenSize.width,
        _screenSize.height - minimizedNowHeight,
      );

  /// Gets the height of the minimized now bar which is based on the height
  /// of the screen.
  double get minimizedNowHeight =>
      _formFactor != FormFactor.phoneLandscape ? 48.0 : 32.0;

  /// Gets the height of the maximized now.
  double get maximizedNowHeight =>
      _kMaximizedNowHeightOffset + suggestionPeekHeight;

  /// The width of the suggestion list.
  double get suggestionListWidth => _suggestionListWidth;

  /// The width of a suggestion.
  double get suggestionWidth => _suggestionWidth;

  /// The distance from the left of the screen interruptions should show up.
  double get interruptionLeftMargin => _interruptionLeftMargin;

  /// The height of the ask input section of the suggestion list
  double get askHeight => _formFactor != FormFactor.phoneLandscape
      ? _kAskHeightLarge
      : _kAskHeightSmall;

  /// Peek height of the suggestion list
  double get suggestionPeekHeight => _kSuggestionPeekHeight[_formFactor]!;

  /// Height of the suggestion list when it is expanded
  double get suggestionExpandedHeight => screenSize.height * 0.8;

  /// The top padding of the story list
  double get storyListTopPadding => screenSize.height / 8.0;
}
