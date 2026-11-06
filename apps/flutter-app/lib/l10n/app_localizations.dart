import 'dart:convert';

import 'package:flutter/material.dart';

/// ترجمات التطبيق للغة العربية والإنجليزية.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── ترجمات العربية ──
  static const Map<String, String> _arStrings = {
    'app_title': 'تطبيق فلتر',
    'welcome': 'مرحباً بك في تطبيق فلتر',
    'subtitle': 'تطبيق إدارة الطلبات والمناديب',
    'add_order': 'إضافة طلب جديد',
    'home': 'الرئيسية',
    'orders': 'الطلبات',
    'deliveries': 'التوصيلات',
    'profile': 'الملف الشخصي',
    'settings': 'الإعدادات',
    'language': 'اللغة',
    'theme': 'السمة',
    'light_mode': 'الوضع الفاتح',
    'dark_mode': 'الوضع الداكن',
    'arabic': 'العربية',
    'english': 'الإنجليزية',
    'loading': 'جاري التحميل...',
    'error': 'حدث خطأ',
    'retry': 'محاولة مرة أخرى',
    'no_data': 'لا توجد بيانات',
    'success': 'تم بنجاح',
    'logout': 'تسجيل الخروج',
    'login': 'تسجيل الدخول',
    'phone': 'رقم الهاتف',
    'password': 'كلمة المرور',
    'sign_in': 'تسجيل الدخول',
    'create_account': 'إنشاء حساب جديد',
  };

  // ── ترجمات الإنجليزية ──
  static const Map<String, String> _enStrings = {
    'app_title': 'Filter App',
    'welcome': 'Welcome to Filter App',
    'subtitle': 'Orders and Delivery Management App',
    'add_order': 'Add New Order',
    'home': 'Home',
    'orders': 'Orders',
    'deliveries': 'Deliveries',
    'profile': 'Profile',
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'light_mode': 'Light Mode',
    'dark_mode': 'Dark Mode',
    'arabic': 'Arabic',
    'english': 'English',
    'loading': 'Loading...',
    'error': 'An error occurred',
    'retry': 'Retry',
    'no_data': 'No data available',
    'success': 'Success',
    'logout': 'Logout',
    'login': 'Login',
    'phone': 'Phone Number',
    'password': 'Password',
    'sign_in': 'Sign In',
    'create_account': 'Create New Account',
  };

  String? translate(String key) {
    if (locale.languageCode == 'ar') {
      return _arStrings[key];
    }
    return _enStrings[key];
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'ar' || locale.languageCode == 'en';
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
