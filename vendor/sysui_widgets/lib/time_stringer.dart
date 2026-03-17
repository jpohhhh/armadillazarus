// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

// ARMADILLAZARUS(parity): Original used intl package DateFormat.
// Replaced with manual formatting to avoid adding the dependency.
// Original format strings preserved in comments.

const _kMonthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
const _kDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

String _formatTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Creates time strings and notifies when they change.
class TimeStringer extends Listenable {
  final Set<VoidCallback> _listeners = <VoidCallback>{};
  Timer? _timer;
  int _offsetMinutes = 0;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    if (_listeners.length == 1) {
      _scheduleTimer();
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Returns the time only (eg. '10:34'). Original: DateFormat('h:mm')
  String get timeOnly => _formatTime(DateTime.now()).toUpperCase();

  /// Returns the date only (eg. 'MONDAY AUG 3'). Original: DateFormat('EEEE MMM d')
  String get dateOnly {
    final now = DateTime.now();
    final day = _kDays[now.weekday - 1];
    final month = _kMonthsShort[now.month - 1];
    return '$day $month ${now.day}'.toUpperCase();
  }

  /// Returns a short version of the time (eg. '10:34'). Original: DateFormat('h:mm')
  String get shortString => _formatTime(DateTime.now()).toLowerCase();

  /// Returns a long version of the time including the day. Original: DateFormat('EEEE h:mm')
  String get longString {
    final now = DateTime.now();
    final day = _kDays[now.weekday - 1].toLowerCase();
    return '$day ${_formatTime(now).toLowerCase()}';
  }

  /// Returns the meridiem (eg. 'AM'). Original: DateFormat('a')
  String get meridiem => DateTime.now().hour >= 12 ? 'PM' : 'AM';

  /// Returns the offset, in minutes.
  int get offsetMinutes => _offsetMinutes;

  set offsetMinutes(int offsetMinutes) {
    if (_offsetMinutes != offsetMinutes) {
      _offsetMinutes = offsetMinutes;
      _notifyListeners();
    }
  }

  void _scheduleTimer() {
    _timer?.cancel();
    _timer =
        new Timer(new Duration(seconds: 61 - new DateTime.now().second), () {
      _notifyListeners();
      _scheduleTimer();
    });
  }

  void _notifyListeners() {
    for (VoidCallback listener in _listeners.toList()) {
      listener();
    }
  }
}
