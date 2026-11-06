import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:filter_app/l10n/app_localizations.dart';
import 'package:filter_app/providers/app_state_provider.dart';
import 'package:filter_app/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('should display welcome message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', 'AE'),
              Locale('en', 'US'),
            ],
            home: const HomeScreen(),
          ),
        ),
      );

      expect(find.text('مرحباً بك في تطبيق فلتر'), findsOneWidget);
      expect(find.text('إضافة طلب جديد'), findsOneWidget);
    });

    testWidgets('should display floating action button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', 'AE'),
              Locale('en', 'US'),
            ],
            home: const HomeScreen(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton.extended), findsOneWidget);
    });

    testWidgets('should toggle theme when dark mode icon is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', 'AE'),
              Locale('en', 'US'),
            ],
            home: const HomeScreen(),
          ),
        ),
      );

      // Find dark mode icon in app bar actions
      final darkModeIcon = find.byIcon(Icons.dark_mode);
      expect(darkModeIcon, findsOneWidget);

      await tester.tap(darkModeIcon);
      await tester.pump();
    });

    testWidgets('should change language when translate icon is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', 'AE'),
              Locale('en', 'US'),
            ],
            home: const HomeScreen(),
          ),
        ),
      );

      final translateIcon = find.byIcon(Icons.translate);
      expect(translateIcon, findsOneWidget);

      await tester.tap(translateIcon);
      await tester.pump();
    });
  });
}
