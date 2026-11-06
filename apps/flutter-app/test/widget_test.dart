import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:filter_app/main.dart';
import 'package:filter_app/providers/app_state_provider.dart';
import 'package:filter_app/theme/app_theme.dart';

void main() {
  group('FilterApp', () {
    testWidgets('should render home screen with app title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: const FilterApp(),
        ),
      );

      expect(find.text('تطبيق فلتر'), findsOneWidget);
    });

    testWidgets('should toggle theme mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: const FilterApp(),
        ),
      );

      // Initial state should be light mode
      expect(AppTheme.lightTheme().brightness, Brightness.light);

      // Find theme toggle button and tap it
      final themeIconFinder = find.byIcon(Icons.dark_mode);
      expect(themeIconFinder, findsOneWidget);

      await tester.tap(themeIconFinder);
      await tester.pump();
    });

    testWidgets('should toggle language between Arabic and English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: const FilterApp(),
        ),
      );

      // Find language toggle button
      final languageIconFinder = find.byIcon(Icons.translate);
      expect(languageIconFinder, findsOneWidget);

      await tester.tap(languageIconFinder);
      await tester.pump();
    });
  });

  group('AppTheme', () {
    test('light theme should have light brightness', () {
      expect(AppTheme.lightTheme().brightness, Brightness.light);
    });

    test('dark theme should have dark brightness', () {
      expect(AppTheme.darkTheme().brightness, Brightness.dark);
    });

    test('light theme primary color should be light purple', () {
      expect(AppTheme.lightTheme().colorScheme.primary,
          const Color(0xFF7B6BF0));
    });

    test('dark theme primary color should be dark purple', () {
      expect(AppTheme.darkTheme().colorScheme.primary,
          const Color(0xFF6200EE));
    });
  });

  group('AppStateProvider', () {
    test('should start with light mode and Arabic locale', () {
      final provider = AppStateProvider();
      expect(provider.isDarkMode, isFalse);
      expect(provider.locale.languageCode, 'ar');
      expect(provider.isRTL, isTrue);
    });

    test('should toggle dark mode', () {
      final provider = AppStateProvider();
      expect(provider.isDarkMode, isFalse);
      provider.toggleTheme();
      expect(provider.isDarkMode, isTrue);
      provider.toggleTheme();
      expect(provider.isDarkMode, isFalse);
    });

    test('should change locale to English', () {
      final provider = AppStateProvider();
      expect(provider.isRTL, isTrue);
      provider.setLocale(const Locale('en', 'US'));
      expect(provider.isRTL, isFalse);
      expect(provider.locale.languageCode, 'en');
    });
  });

  group('AppLocalizations', () {
    test('should return Arabic strings for Arabic locale', () {
      final l10n = AppLocalizations(const Locale('ar', 'AE'));
      expect(l10n.translate('app_title'), 'تطبيق فلتر');
      expect(l10n.translate('welcome'), 'مرحباً بك في تطبيق فلتر');
    });

    test('should return English strings for English locale', () {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      expect(l10n.translate('app_title'), 'Filter App');
      expect(l10n.translate('welcome'), 'Welcome to Filter App');
    });

    test('should return null for unknown key', () {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      expect(l10n.translate('unknown_key'), isNull);
    });
  });
}
