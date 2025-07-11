import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'presentation/state_management/splash_state.dart';
import 'services/firebase/database/firebase_database_service.dart';
import 'services/auth/auth_service.dart';
import 'presentation/views/auth/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashState()),
        Provider(create: (_) => FirebaseDatabaseService()),
        Provider(create: (context) => AuthService(
          context.read<FirebaseDatabaseService>(), 
        )),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            context.read<AuthService>(),
          )..initialize(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}