import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed google_fonts import for system font stack
import 'screens/onboarding_screen.dart';
import 'screens/food_list_screen.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize database and default tags
  final databaseService = DatabaseService();
  await databaseService.initializeDefaultTags();

  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      (await databaseService.getAllFoodItems()).isNotEmpty &&
      prefs.getBool('onboarding_completed')!;

  runApp(MyApp(hasCompletedOnboarding: hasCompletedOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  const MyApp({super.key, required this.hasCompletedOnboarding});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'GreenBite',
      themeMode: ThemeMode.system,
      // Localization: enable Flutter's built-in localizations and add Vietnamese
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (var supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return supportedLocales.first;
      },
      // Light theme with default Material typography (no custom fontFamily)
      theme: ThemeData(
        colorScheme: LegacyColorSchemes.lightGreen(),
        radius: 0.7,
      ),
      // Dark theme with default Material typography
      darkTheme: ThemeData(
        colorScheme: LegacyColorSchemes.darkGreen(),
        radius: 0.7,
      ),
      home: hasCompletedOnboarding
          ? const FoodListScreen()
          : const OnboardingScreen(),
    );
  }
}
