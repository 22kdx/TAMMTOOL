import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

/// شاشة الرئيسية للتطبيق مع دعم RTL، الثيمات، وحالات التحميل والخطأ والبيانات الفارغة.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('app_title') ?? 'تطبيق فلتر'),
        centerTitle: true,
        actions: [
          // زر تبديل اللغة
          IconButton(
            icon: Icon(appState.isRTL ? Icons.translate : Icons.translate),
            tooltip: l10n.translate('language'),
            onPressed: () {
              appState.setLocale(
                appState.isRTL
                    ? const Locale('en', 'US')
                    : const Locale('ar', 'AE'),
              );
            },
          ),
          // زر تبديل الثيم
          IconButton(
            icon: Icon(
              appState.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: appState.isDarkMode
                ? l10n.translate('light_mode')
                : l10n.translate('dark_mode'),
            onPressed: appState.toggleTheme,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(l10n)
          : _errorMessage != null
              ? _buildErrorState(l10n)
              : _buildContentState(l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () {},
        icon: const Icon(Icons.add),
        label: Text(l10n.translate('add_order') ?? 'إضافة طلب جديد'),
      ),
    );
  }

  /// حالة التحميل
  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            l10n.translate('loading') ?? 'جاري التحميل...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  /// حالة الخطأ
  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('error') ?? 'حدث خطأ',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              // محاكاة محاولة إعادة
              Future.delayed(const Duration(seconds: 2), () {
                setState(() {
                  _isLoading = false;
                });
              });
            },
            child: Text(l10n.translate('retry') ?? 'محاولة مرة أخرى'),
          ),
        ],
      ),
    );
  }

  /// حالة المحتوى العادي
  Widget _buildContentState(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة الترحيب
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('welcome') ?? 'مرحباً بك في تطبيق فلتر',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('subtitle') ??
                        'تطبيق إدارة الطلبات والمناديب',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // بطاقات الإجراء السريع
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.list_alt,
                  label: l10n.translate('orders') ?? 'الطلبات',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.local_shipping,
                  label: l10n.translate('deliveries') ?? 'التوصيلات',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // قسم الملف الشخصي والإعدادات
          Text(
            l10n.translate('settings') ?? 'الإعدادات',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.translate('profile') ?? 'الملف الشخصي'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.translate('logout') ?? 'تسجيل الخروج'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// بطاقة إجراء سريع قابلة لإعادة الاستخدام
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
