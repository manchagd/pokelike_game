import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mix/mix.dart';
import 'theme.dart';
import 'nav.dart';
import 'utils/battle_socket_service.dart';
import 'utils/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<BattleSocketService>(
          create: (_) => BattleSocketService(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.themeMode == ThemeMode.dark ||
              (themeProvider.themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          AppColors.isDark = isDark;
          return MixScope(
            child: MaterialApp.router(
              title: 'Pixel Clash',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(isDark: false),
              darkTheme: buildAppTheme(isDark: true),
              themeMode: themeProvider.themeMode,
              routerConfig: AppRouter.router,
            ),
          );
        },
      ),
    );
  }
}
