import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/config/routes.dart';
import 'core/config/env_config.dart';
import 'core/providers/core_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser la configuration d'environnement
  await EnvConfig.init();
  EnvConfig.printConfig();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }

  await initializeDateFormatting('fr', null);

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const PharmacyApp(),
    ),
  );
}

class PharmacyApp extends ConsumerStatefulWidget {
  const PharmacyApp({super.key});

  @override
  ConsumerState<PharmacyApp> createState() => _PharmacyAppState();
}

class _PharmacyAppState extends ConsumerState<PharmacyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  Future<void> _initNotifications() async {
    try {
      await ref.read(notificationServiceProvider).initialize();
    } catch (e) {
      debugPrint("Error initializing notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    
    // Obtenir la couleur d'accent dynamique
    Color? accentColor;
    if (themeState.customAccentColor != null) {
      final colorKey = themeState.customAccentColor!;
      accentColor = AppThemes.accentColors[colorKey];
    }

    return MaterialApp.router(
      title: 'DR-PHARMA Pharmacie',
      theme: AppThemes.lightTheme(accentColor: accentColor),
      darkTheme: AppThemes.darkTheme(accentColor: accentColor),
      themeMode: themeState.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''), // French
      ],
      locale: const Locale('fr', ''),
    );
  }
}