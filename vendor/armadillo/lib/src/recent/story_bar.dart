// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:sysui_widgets/three_column_aligned_layout_delegate.dart';

import 'story.dart';
import 'story_title.dart';

const RK4SpringDescription _kHeightSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kPartMargin = 8.0;

const bool _kShowTitleOnly = true;

/// The bar to be shown at the top of a story.
class StoryBar extends StatelessWidget {
  /// The [Story] this bar represents.
  final Story story;

  /// True if the story should show its title only.
  final bool showTitleOnly;

  /// Elevation for the Physical Model that wraps the StoryBar
  final double elevation;

  /// BorderRadius for the Physical Model that wraps the StoryBar
  final BorderRadius borderRadius;

  /// Constructor.
  const StoryBar({
    required this.story,
    this.showTitleOnly = _kShowTitleOnly,
    this.elevation = 0.0,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) =>
      SizeModel.kStoryBarMinimizedHeight == 0.0 &&
              SizeModel.kStoryBarMaximizedHeight == 0.0
          ? Nothing.widget
          : new PhysicalModel(
              clipBehavior: Clip.antiAlias,
              color: story.themeColor,
              elevation: elevation,
              borderRadius: borderRadius,
              child: new ScopedModelDescendant<StoryBarHeightModel>(
                builder: (
                  _,
                  Widget? child,
                  StoryBarHeightModel storyBarHeightModel,
                ) =>
                    new ScopedModelDescendant<StoryBarFocusModel>(
                  builder: (
                    _,
                    Widget? child,
                    StoryBarFocusModel storyBarFocusModel,
                  ) =>
                      _buildStoryBar(
                    context,
                    storyBarHeightModel.value,
                    storyBarFocusModel.value,
                  ),
                ),
              ),
            );

  Widget _buildStoryBar(
    BuildContext context,
    double heightValue,
    double focusValue,
  ) =>
      new Container(
        color: story.themeColor,
        height: heightValue - focusValue,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        margin: new EdgeInsets.only(bottom: focusValue),
        child: new OverflowBox(
          minHeight: SizeModel.kStoryBarMaximizedHeight,
          maxHeight: SizeModel.kStoryBarMaximizedHeight,
          alignment: FractionalOffset.topCenter,
          child: showTitleOnly
              ? new Center(
                  child: new StoryTitle(
                    title: story.title,
                    opacity: _opacity(heightValue),
                    baseColor: _textColor,
                  ),
                )
              : new Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0.0,
                    vertical: 12.0,
                  ),
                  child: new CustomMultiChildLayout(
                    delegate: new ThreeColumnAlignedLayoutDelegate(
                      partMargin: _kPartMargin,
                    ),
                    children: <Widget>[
                      /// Module icons for the current story.
                      new LayoutId(
                        id: ThreeColumnAlignedLayoutDelegateParts.left,
                        child: new Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: story.icons
                              .map(
                                (OpacityBuilder builder) => builder(
                                  context,
                                  _opacity(heightValue),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      /// Story title.
                      new LayoutId(
                        id: ThreeColumnAlignedLayoutDelegateParts.center,
                        child: new StoryTitle(
                          title: story.title,
                          opacity: _opacity(heightValue),
                          baseColor: _textColor,
                        ),
                      ),

                      /// For future use.
                      new LayoutId(
                        id: ThreeColumnAlignedLayoutDelegateParts.right,
                        child: Nothing.widget,
                      ),
                    ],
                  ),
                ),
        ),
      );

  Color get _textColor {
    // See http://www.w3.org/TR/AERT#color-contrast for the details of this
    // algorithm.
    int brightness = (((story.themeColor.red * 299) +
                (story.themeColor.green * 587) +
                (story.themeColor.blue * 114)) /
            1000)
        .round();

    return (brightness > 125) ? Colors.black : Colors.white;
  }

  double _opacity(double heightValue) => math
      .max(
          0.0,
          (heightValue - SizeModel.kStoryBarMinimizedHeight) /
              (SizeModel.kStoryBarMaximizedHeight -
                  SizeModel.kStoryBarMinimizedHeight))
      .clamp(0.0, 1.0);
}

/// Handles the transition when the story bar minimizes and maximizes.
class StoryBarHeightModel extends SpringModel {
  double _showHeight = SizeModel.kStoryBarMinimizedHeight;

  /// Constructor.
  StoryBarHeightModel() : super(springDescription: _kHeightSimulationDesc) {
    jump(_showHeight);
  }

  /// Shows the story bar.
  void show() {
    target = _showHeight;
  }

  /// Hides the story bar.
  void hide() {
    target = 0.0;
  }

  /// Maximizes the height of the story bar when shown.  If [jumpToFinish] is
  /// true the story bar height will jump to its maximized value instead of
  /// transitioning to it.
  void maximize({bool jumpToFinish = false}) {
    if (jumpToFinish) {
      jump(SizeModel.kStoryBarMaximizedHeight);
    }
    _showHeight = SizeModel.kStoryBarMaximizedHeight;
    show();
  }

  /// Minimizes the height of the story bar when shown.
  void minimize() {
    _showHeight = SizeModel.kStoryBarMinimizedHeight;
    show();
  }
}

const double _kStoryBarUnfocusedBottomGapHeight = 4.0;

/// Handles the transition when the story becomes focused.
class StoryBarFocusModel extends SpringModel {
  bool _focused = false;
  bool _minimized = true;

  /// Constructor.
  StoryBarFocusModel() : super(springDescription: _kHeightSimulationDesc);

  /// Maximizes the height of the story bar when shown.
  void maximize() {
    _minimized = false;
    target = _focused ? 0.0 : _kStoryBarUnfocusedBottomGapHeight;
  }

  /// Minimizes the height of the story bar when shown.
  void minimize() {
    _minimized = true;
    target = 0.0;
  }

  /// Sets the story bar into focus mode if true.
  set focus(bool focus) {
    if (_focused != focus) {
      _focused = focus;
      if (!_minimized) {
        target = _focused ? 0.0 : _kStoryBarUnfocusedBottomGapHeight;
      }
    }
  }
}
