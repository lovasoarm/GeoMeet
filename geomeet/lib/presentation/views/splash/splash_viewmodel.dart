import 'package:flutter/material.dart';
import '../../../data/models/splash_model.dart';

class SplashViewmodel extends ChangeNotifier {
  SplashModel model = SplashModel();
  int get totalDesc => _desc.length;
  List<Splash> _desc = [];
  List<Splash> get desc => _desc;
  void getDescription() {
    _desc = model.getDescriptions();
    notifyListeners();
  }
}
