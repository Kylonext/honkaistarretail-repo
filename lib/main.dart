import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/login_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  runApp(const GachaMerchApp());
}

class GachaMerchApp extends StatelessWidget {
  const GachaMerchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          title: 'Honkai Star Retail',
          debugShowCheckedModeBanner: false,
          theme: SpaceTheme.lightTheme,
          darkTheme: SpaceTheme.darkTheme,
          themeMode: currentMode,
          home: const LoginPage(),
        );
      },
    );
  }
}