import 'package:flutter/material.dart';
import '../views/splash/splash_viewmodel.dart';

class SplashState extends ChangeNotifier {
  final SplashViewmodel viewmodel = SplashViewmodel();
  int currentIndex = 0;
  final PageController _pageController = PageController();

  SplashState() {
    viewmodel.getDescription();
  }

  void nextPage() {
    if (currentIndex < viewmodel.totalDesc - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      currentIndex++;
      notifyListeners();
    }
  }

  PageController get pageController => _pageController;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
