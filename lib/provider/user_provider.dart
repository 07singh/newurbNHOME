import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _name = "";
  String _role = "";

  String get name => _name;
  String get role => _role;

  void setUser(String name, String role) {
    _name = name;
    _role = role;
    notifyListeners();
  }
}
