import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';

/// Settings screen for theme and language selection
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.isGlassTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'settings'.tr(),
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isGlass
                ? [
                    const Color(0xFF1E1E2E),
                    const Color(0xFF2D1B4E),
                    const Color(0xFF1E1E2E),
                  ]
                : [
                    const Color(0xFF0F0F0F),
                    const Color(0xFF1A0E2E),
                    const Color(0xFF0F0F0F),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'language'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Language options
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionItem(
                          context: context,
                          title: 'english'.tr(),
                          isSelected: context.locale.languageCode == 'en',
                          isGlass: isGlass,
                          onTap: () => context.setLocale(const Locale('en')),
                          icon: Icons.language_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOptionItem(
                          context: context,
                          title: 'turkish'.tr(),
                          isSelected: context.locale.languageCode == 'tr',
                          isGlass: isGlass,
                          onTap: () => context.setLocale(const Locale('tr')),
                          icon: Icons.language_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'theme'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Dark theme option
                  _buildThemeOption(
                    context: context,
                    title: 'dark_mode'.tr(),
                    description: 'dark_mode_desc'.tr(),
                    isSelected: !isGlass,
                    isGlass: isGlass,
                    onTap: () => themeProvider.setTheme(false),
                    icon: Icons.dark_mode_rounded,
                  ),

                  const SizedBox(height: 12),

                  // Glass theme option
                  _buildThemeOption(
                    context: context,
                    title: 'liquid_glass'.tr(),
                    description: 'liquid_glass_desc'.tr(),
                    isSelected: isGlass,
                    isGlass: isGlass,
                    onTap: () => themeProvider.setTheme(true),
                    icon: Icons.blur_on_rounded,
                  ),

                  const SizedBox(height: 32),

                  // App info
                  _buildGlassContainer(
                    isGlass: isGlass,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'about'.tr(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Music App v1.0.0',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'app_desc'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required bool isGlass,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return _buildGlassContainer(
      isGlass: isGlass,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white60,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String description,
    required bool isSelected,
    required bool isGlass,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return _buildGlassContainer(
      isGlass: isGlass,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ]
                        : [const Color(0x1AFFFFFF), const Color(0x0DFFFFFF)],
                  ),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required bool isGlass, required Widget child}) {
    if (isGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: child,
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0x4D000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }
  }
}
