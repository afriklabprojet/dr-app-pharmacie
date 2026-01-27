import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/widgets.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Paramètres',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 100),
          child: ModernCard(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.shield_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Sécurité',
                  subtitle: 'PIN, Biométrie, Session',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/security-settings');
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.blue,
                  title: 'Notifications',
                  subtitle: 'Gérer vos préférences',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/notification-settings');
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.language_outlined,
                  iconColor: Colors.purple,
                  title: 'Langue',
                  subtitle: 'Français',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showLanguageSelector(context);
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Aide & Support',
                  subtitle: 'FAQ, Contact',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/help-support');
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'À propos',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 200),
          child: ModernCard(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  iconColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  title: 'Version',
                  subtitle: '1.0.0 (Build 1)',
                  showChevron: false,
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.description_outlined,
                  iconColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  title: 'Conditions d\'utilisation',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/terms');
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  title: 'Politique de confidentialité',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/privacy');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Choisir la langue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            _buildLanguageOption(context, 'Français', 'fr', true),
            _buildLanguageOption(context, 'English', 'en', false),
            _buildLanguageOption(context, 'العربية', 'ar', false),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, String code, bool isSelected) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('La langue sera disponible prochainement'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          code.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ),
      title: Text(
        language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }
}
