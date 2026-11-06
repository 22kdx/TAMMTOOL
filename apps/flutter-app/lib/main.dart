import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_state_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const FilterApp(),
    ),
  );
}

class FilterApp extends StatelessWidget {
  const FilterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: AppLocalizations.of(context)?.translate('app_title') ??
              'تطبيق فلتر',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: appState.locale,
          supportedLocales: const [
            Locale('ar', 'AE'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        );
      },
    );
  }
}
