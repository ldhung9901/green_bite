import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed google_fonts import for system font stack
import 'screens/onboarding_screen.dart';
import 'screens/food_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;

  runApp(MyApp(hasCompletedOnboarding: hasCompletedOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  const MyApp({super.key, required this.hasCompletedOnboarding});

  List<String> get _fontFallback => const [
        // CSS stack mapping attempt
        'BlinkMacSystemFont', // macOS Chrome
        'Segoe UI', // Windows
        'Roboto', // Android / ChromeOS
        'Helvetica Neue', // Older macOS / iOS
        'Arial',
        'Noto Sans', // Wide unicode coverage
        'sans-serif', // Generic family (ignored if not resolved)
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Segoe UI Symbol',
        'Noto Color Emoji',
      ];

  String _primaryPlatformFont(TargetPlatform p) {
    switch (p) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '.SF UI Display'; // Apple system font internal PostScript name
      case TargetPlatform.android:
        return 'Roboto';
      case TargetPlatform.windows:
        return 'Segoe UI';
      case TargetPlatform.linux:
        return 'Noto Sans';
      case TargetPlatform.fuchsia:
        return 'Roboto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'GreenBite',
      themeMode: ThemeMode.system,
      // Light theme
      theme: ThemeData(
        colorScheme: LegacyColorSchemes.lightGreen(),
        radius: 0.7,
      ),
      // Dark theme
      darkTheme: ThemeData(
        colorScheme: LegacyColorSchemes.darkGreen(),
        radius: 0.7,
      ),
      home: Builder(
        builder: (context) {
          final platform = Theme.of(context).platform;
          final systemFont = _primaryPlatformFont(platform);
          final textStyle = TextStyle(
            fontFamily: systemFont,
            fontFamilyFallback: _fontFallback,
            height: 1,
          );
            return DefaultTextStyle(
              style: textStyle,
              child: hasCompletedOnboarding
                  ? const FoodListScreen()
                  : const OnboardingScreen(),
            );
        },
      ),
    );
  }
}
