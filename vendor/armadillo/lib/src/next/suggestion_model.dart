// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/recent.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'suggestion.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// The base class for suggestion models.
abstract class SuggestionModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static SuggestionModel of(BuildContext context) =>
      new ModelFinder<SuggestionModel>().of(context);

  /// Returns the list of suggestions from the current ask query
  List<Suggestion> get askSuggestions;

  /// Retruns the list of suggestion from the next space
  List<Suggestion> get nextSuggestions;

  /// Sets the ask text to [text].
  set askText(String text);

  /// Gets the ask text.
  String get askText;

  /// Sets the asking state to [asking].
  set asking(bool asking);

  /// Gets the asking state.
  bool get asking;

  /// Returns true if an ask is being processed.
  bool get processingAsk;

  /// Returns true if a next is being processed.
  bool get processingNext;

  /// Called when a suggestion is selected by the user.
  void onSuggestionSelected(Suggestion suggestion);
}
