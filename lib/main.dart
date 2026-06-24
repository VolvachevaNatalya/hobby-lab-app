import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hobby_lab/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'locale_provider.dart';
import 'navigation_key.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedLocale();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final token = await ApiService.getSavedToken();
  runApp(HobbyLabApp(isLoggedIn: token != null));
}

class HobbyLabApp extends StatefulWidget {
  final bool isLoggedIn;
  const HobbyLabApp({super.key, required this.isLoggedIn});

  @override
  State<HobbyLabApp> createState() => _HobbyLabAppState();
}

class _HobbyLabAppState extends State<HobbyLabApp> {
  @override
  void initState() {
    super.initState();
    ApiService.authNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    ApiService.authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!ApiService.authNotifier.value) {
      globalNavigatorKey.currentState?.pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const SplashScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) => MaterialApp(
        title: 'Hobby Lab',
        navigatorKey: globalNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: locale,
        supportedLocales: const [
          Locale('en'),
          Locale('ru'),
          Locale('he'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: widget.isLoggedIn ? const MainShell() : const SplashScreen(),
      ),
    );
  }
}
