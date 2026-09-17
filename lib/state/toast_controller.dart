import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tiny toast/snackbar-style notifier, decoupled from BuildContext so the
/// domain controller can raise user-facing messages from anywhere.
class ToastController extends ChangeNotifier {
  String? _message;
  int _token = 0;
  Timer? _timer;

  String? get message => _message;

  void show(String message, {Duration duration = const Duration(milliseconds: 2800)}) {
    _message = message;
    _token++;
    final myToken = _token;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (_token == myToken) {
        _message = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
