import 'package:flutter/material.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/theme/app_theme.dart';
import 'package:nbts/core/theme/theme_controller.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/features/splash/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Services.instance.init();
  runApp(const NBTSApp());
}

class NBTSApp extends StatelessWidget {
  const NBTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'NBTS Vitality',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: const SplashScreen(),
        routes: AppRoutes.routes,
      ),
    );
  }
}
