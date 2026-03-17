// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/now.dart';
import 'package:armadillo/recent.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'peeking_overlay.dart';

/// Determines if a [PeekingOverlay] should be peeking or not.
class PeekModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static PeekModel of(BuildContext context) =>
      new ModelFinder<PeekModel>().of(context);

  bool _nowMinimized = false;
  bool _isDragging = false;
  bool _quickSettingsOpen = false;
  double _lastQuickSettingsProgress = 0.0;

  /// Sets whether now is minimized or not.
  set nowMinimized(bool value) {
    if (_nowMinimized != value) {
      _nowMinimized = value;
      notifyListeners();
    }
  }

  /// Called when the [StoryClusterDragStateModel] changes.
  void onStoryClusterDragStateModelChanged(
    StoryClusterDragStateModel storyClusterDragStateModel,
  ) {
    if (_isDragging != storyClusterDragStateModel.isDragging) {
      _isDragging = storyClusterDragStateModel.isDragging;
      notifyListeners();
    }
  }

  /// Called when the quick settings opening progress changes.
  void onQuickSettingsProgressChanged(double quickSettingsProgress) {
    if (_lastQuickSettingsProgress != quickSettingsProgress) {
      bool quickSettingsOpen =
          quickSettingsProgress > _lastQuickSettingsProgress;
      _lastQuickSettingsProgress = quickSettingsProgress;
      if (_quickSettingsOpen != quickSettingsOpen) {
        _quickSettingsOpen = quickSettingsOpen;
        notifyListeners();
      }
    }
  }

  /// Returns true if the [PeekingOverlay] should be peeking.
  bool get peek => !_nowMinimized && !_isDragging && !_quickSettingsOpen;
}
