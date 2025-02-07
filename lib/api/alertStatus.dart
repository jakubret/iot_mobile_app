import 'package:flutter/material.dart';

class AlertStatusNotifier with ChangeNotifier {
  bool _hasAlerts = false;

  bool get hasAlerts => _hasAlerts;

  void setAlerts(bool value) {
    if (_hasAlerts != value) {
      _hasAlerts = value;
      notifyListeners();
    }
  }
}
