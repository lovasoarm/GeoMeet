import 'package:flutter/material.dart';
import '../../widgets/auth_widget.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AuthViewState createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool isLogin = true;

  void toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBody(
        isLogin: isLogin,
        onToggleAuthMode: toggleAuthMode,
      ),
    );
  }
}