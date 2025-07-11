import 'package:flutter/material.dart';
import 'package:geomeet/presentation/views/home/add_friend.dart';
import 'package:geomeet/presentation/views/home/home_view.dart';
import 'package:geomeet/presentation/views/home/notification_view.dart';
import 'package:provider/provider.dart';
import '../presentation/state_management/splash_state.dart';
import '../presentation/views/splash/splash_view.dart';
import 'routes.dart';
import '../presentation/views/tracking/location_view.dart';
import '../presentation/views/auth/auth_view.dart';
import 'package:geomeet/data/models/user_model.dart'; 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GeoMeet',
      initialRoute: AppRoutes.splashscreen,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splashscreen:
            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: Provider.of<SplashState>(context, listen: false),
                child: const Splashscreen(),
              ),
            );

          case AppRoutes.authview:
            return MaterialPageRoute(builder: (_) => const AuthView());

          case AppRoutes.homeview:
            return MaterialPageRoute(builder: (_) => const HomeView());

          case AppRoutes.addFriend:
            return MaterialPageRoute(builder: (_) => const AddFriendPage());

          case AppRoutes.notification:
            return MaterialPageRoute(builder: (_) => const NotificationView());

          case AppRoutes.locationview:
            final args = settings.arguments;
            if (args is User) {
              return MaterialPageRoute(
                builder: (_) => LocationTrackingView(friend: args),
              );
            } else {
              return _errorRoute('Données de suivi manquantes');
            }

          default:
            return _errorRoute('Route inconnue');
        }
      },
    );
  }

  Route _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
