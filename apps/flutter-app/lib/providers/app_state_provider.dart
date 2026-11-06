import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// حالة التطبيق العالمية: الثيم واللغة.
class AppStateProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  Locale _locale = const Locale('ar', 'AE'); // العربية (الإمارات) لاتجاه RTL

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;
  bool get isRTL => _locale.languageCode == 'ar';

  /// تبديل الوضع الفاتح/الداكن
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// تغيير اللغة
  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  /// إعادة التعيين للقيم الافتراضية
  void reset() {
    _isDarkMode = false;
    _locale = const Locale('ar', 'AE');
    notifyListeners();
  }
}
