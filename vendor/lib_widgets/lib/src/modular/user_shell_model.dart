// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:lib.app.dart/app.dart';
import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:lib.widgets/model.dart';
import 'package:meta/meta.dart';

export 'package:fidl_fuchsia_modular/fidl.dart'
    show
        ContextReader,
        ContextWriter,
        SuggestionProvider,
        Link,
        StoryProvider,
        FocusProvider,
        FocusController,
        VisibleStoriesController,
        UserShellContext,
        IntelligenceServices;
export 'package:lib.widgets/model.dart' show ScopedModel, ScopedModelDescendant;

/// The [Model] that provides services provided to this app's [UserShell].
class UserShellModel extends Model {
  UserShellContext _userShellContext;
  FocusProvider _focusProvider;
  FocusController _focusController;
  VisibleStoriesController _visibleStoriesController;
  StoryProvider _storyProvider;
  SuggestionProvider _suggestionProvider;
  ContextReader _contextReader;
  ContextWriter _contextWriter;
  IntelligenceServices _intelligenceServices;
  Link _link;

  /// Indicates whether the [LinkWatcher] should watch for all changes including
  /// the changes made by this [UserShell]. If `true`, it calls [Link.watchAll]
  /// to register the [LinkWatcher], and [Link.watch] otherwise. Only takes
  /// effect when the [onNotify] callback is also provided. Defaults to `false`.
  final bool watchAll;

  /// The [StartupContext] given to this app's [UserShell];
  final StartupContext startupContext;

  /// Creates a new instance of [UserShellModel].
  UserShellModel({bool watchAll, this.startupContext})
      : watchAll = watchAll ?? false;

  /// The [UserShellContext] given to this app's [UserShell].
  UserShellContext get userShellContext => _userShellContext;

  /// The [FocusProvider] given to this app's [UserShell].
  FocusProvider get focusProvider => _focusProvider;

  /// The [FocusController] given to this app's [UserShell].
  FocusController get focusController => _focusController;

  /// The [VisibleStoriesController] given to this app's [UserShell].
  VisibleStoriesController get visibleStoriesController =>
      _visibleStoriesController;

  /// The [StoryProvider] given to this app's [UserShell].
  StoryProvider get storyProvider => _storyProvider;

  /// The [SuggestionProvider] given to this app's [UserShell].
  SuggestionProvider get suggestionProvider => _suggestionProvider;

  /// The [ContextReader] given to this app's [UserShell].
  ContextReader get contextReader => _contextReader;

  /// The [ContextWriter] given to this app's [UserShell].
  ContextWriter get contextWriter => _contextWriter;

  /// The [IntelligenceServices] given to this app's [UserShell].
  IntelligenceServices get intelligenceServices => _intelligenceServices;

  /// The [Link] given to this [UserShell].
  Link get link => _link;

  /// Called when this app's [UserShell] is given its services.
  @mustCallSuper
  void onReady(
    UserShellContext userShellContext,
    FocusProvider focusProvider,
    FocusController focusController,
    VisibleStoriesController visibleStoriesController,
    StoryProvider storyProvider,
    SuggestionProvider suggestionProvider,
    ContextReader contextReader,
    ContextWriter contextWriter,
    IntelligenceServices intelligenceServices,
    Link link,
  ) {
    _userShellContext = userShellContext;
    _focusProvider = focusProvider;
    _focusController = focusController;
    _visibleStoriesController = visibleStoriesController;
    _storyProvider = storyProvider;
    _suggestionProvider = suggestionProvider;
    _contextReader = contextReader;
    _contextWriter = contextWriter;
    _intelligenceServices = intelligenceServices;
    _link = link;
    notifyListeners();
  }

  /// Called when the app's [UserShell] stops.
  void onStop() => null;

  /// Called when [LinkWatcher.notify] is called.
  void onNotify(String json) => null;
}
