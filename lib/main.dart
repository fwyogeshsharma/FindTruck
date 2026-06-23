import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/auth_service.dart';
import 'data/truck_repository.dart';
import 'screens/auth/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const TruckFinderApp());
}

class TruckFinderApp extends StatelessWidget {
  const TruckFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Shared API client → FreightDesk. AuthService sets the bearer token on it;
    // the truck repository reads from the same client.
    final api = ApiClient();
    final TruckRepository repo = RestTruckRepository(api);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(api)),
        ChangeNotifierProvider(create: (_) => AppState(repo)),
      ],
      child: MaterialApp(
        title: 'truckfinder',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
