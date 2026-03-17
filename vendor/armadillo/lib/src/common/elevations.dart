// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// PhysicalModel elevation values for various UI elements
class Elevations {
  /// The maximum elevation a module has.  This is an estimate.
  static const double moduleMaxElevation = 50.0;

  /// The maximum elevation story shell is using.  This is an estimate.
  static const double storyShellMaxElevation = 200.0;

  static const double _storyShellWithModuleMaxElevation =
      moduleMaxElevation + storyShellMaxElevation;

  /// Elevation for the suggestion list overlay
  static const double suggestionList =
      (3 * _storyShellWithModuleMaxElevation) + 10.0;

  /// Elevation for an interruption
  static const double interruption =
      (3 * _storyShellWithModuleMaxElevation) + 20.0;

  /// Elevation for story cluster when it is being dragged
  static const double draggedStoryCluster =
      3 * _storyShellWithModuleMaxElevation;

  /// Elevation for story cluster when it is focused
  static const double focusedStoryCluster = _storyShellWithModuleMaxElevation;

  /// Elevation for quick settings overlay
  static const double quickSettings =
      (3 * _storyShellWithModuleMaxElevation) + 20.0;

  /// Elevation for suggestion expand overlay
  static const double suggestionExpand =
      (3 * _storyShellWithModuleMaxElevation) + 20.0;

  /// Elevation for a story cluster when it is in inline preview mode
  static const double storyClusterInlinePreview =
      2 * _storyShellWithModuleMaxElevation;

  /// Additional elevation to give a focused story tab
  static const double focusedStoryTab = 8.0;

  /// The elevation of Now's user when quick settings are open
  static const double nowUserQuickSettingsOpen = 3.0;
}
