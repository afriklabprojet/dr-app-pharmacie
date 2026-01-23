import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/entities/pharmacy_entity.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../on_call/presentation/pages/on_call_page.dart';
import 'edit_pharmacy_page.dart';
import 'edit_profile_page.dart';
import '../../../../core/theme/app_colors.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            fontSize: 20, // Slightly reduced
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Consumer(
              builder: (context, ref, child) {
                final unreadCount = ref.watch(unreadNotificationCountProvider);
                return Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount.toString()),
                  child: const Icon(Icons.notifications_outlined, color: Colors.black87),
                );
              },
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8), // Consistent spacing
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header centered
            Center(child: _buildProfileHeader(user)),
            
            const SizedBox(height: 24),

            // Infos Contact
            _buildSectionTitle('Coordonnées'),
            const SizedBox(height: 12),
            _buildInfoSection(context, user),

            const SizedBox(height: 32),

            // Pharmacies
            if (user.pharmacies.isNotEmpty) ...[
              _buildSectionTitle('Ma Pharmacie'),
              const SizedBox(height: 12),
              _buildPharmacyCard(context, user.pharmacies.first),
            ] else if (user.role?.toLowerCase() == 'pharmacy') ...[
              _buildSectionTitle('Ma Pharmacie'),
              const SizedBox(height: 12),
              _buildEmptyState(),
            ],

            const SizedBox(height: 32),

            // Bouton Déconnexion
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[400],
                  side: BorderSide(color: Colors.red.withOpacity(0.2), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Se déconnecter',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity user) {
    return Column(
      children: [
        _buildAvatar(user),
        const SizedBox(height: 12),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _getFormattedRoleAndLocation(user),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Card(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
               Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey),
               SizedBox(height: 12),
               Text(
                "Aucune pharmacie associée",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Me déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
         await ref.read(authProvider.notifier).logout();
         
         if (context.mounted) {
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(
               builder: (context) => const LoginPage(),
             ),
             (route) => false,
           );
         }
      }
    }
  }

  String _getFormattedRoleAndLocation(UserEntity user) {
    // 1. Format Role
    String roleDisplay = 'Utilisateur';
    if (user.role != null) {
      switch (user.role!.toLowerCase()) {
        case 'pharmacy':
          roleDisplay = 'Pharmacien';
          break;
        case 'admin':
          roleDisplay = 'Administrateur';
          break;
        case 'courier':
          roleDisplay = 'Livreur';
          break;
        default:
          // Capitalize first letter
          if (user.role!.isNotEmpty) {
            roleDisplay = user.role![0].toUpperCase() + user.role!.substring(1);
          }
      }
    }

    // 2. Add Location (if available from pharmacies)
    String? location;
    if (user.pharmacies.isNotEmpty) {
      // Use the city of the first pharmacy primarily
      location = user.pharmacies.first.city;
    }

    if (location != null && location.isNotEmpty) {
      return '$roleDisplay • $location';
    }

    return roleDisplay;
  }

  Widget _buildAvatar(UserEntity user) {
    // 2. Try Pharmacy Name/Logo (Concepts) -> Fallback to Initials
    // If no user avatar, we use initials with dynamic color
    final String displayName = user.name.isNotEmpty ? user.name : '?';
    final Color dynamicColor = _getDynamicColor(displayName);
    final String initials = _getInitials(displayName);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: user.avatar != null && user.avatar!.isNotEmpty 
            ? Colors.transparent 
            : dynamicColor.withOpacity(0.1),
        backgroundImage: user.avatar != null && user.avatar!.isNotEmpty 
            ? NetworkImage(user.avatar!) 
            : null,
        child: user.avatar != null && user.avatar!.isNotEmpty 
            ? null
            : Text(
                initials,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: dynamicColor,
                ),
              ),
      ),
    );
  }

  Color _getDynamicColor(String text) {
    if (text.isEmpty) return Colors.blue;
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.deepOrange,
    ];
    return colors[text.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    
    if (parts.length == 1) {
      // Just one name, take up to 2 chars if possible, or just 1
      return parts[0].length > 1 
          ? parts[0].substring(0, 2).toUpperCase() 
          : parts[0][0].toUpperCase();
    }
    
    // First and Last name initials
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }


  Widget _buildInfoSection(BuildContext context, UserEntity user) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContactRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
                onTap: () => _launchEmail(user.email),
              ),
              Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 60),
              _buildContactRow(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: user.phone,
                onTap: () => _launchPhone(user.phone),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36, // Hauteur fixe réduite
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(user: user),
                ),
              );
            },
            icon: Icon(Icons.edit_outlined, size: 14, color: Colors.grey[600]),
            label: Text(
              'Modifier mes informations',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // Match container
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(icon, size: 18, color: Colors.grey[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      if (await canLaunchUrl(phoneLaunchUri)) {
        await launchUrl(phoneLaunchUri);
      }
    } catch (e) {
      debugPrint('Could not launch phone: $e');
    }
  }

  Widget _buildPharmacySection(List<PharmacyEntity> pharmacies) {
    // Already handled in the main build method with new layout
    return Column(
      children: pharmacies.map((pharmacy) => Builder(builder: (context) => _buildPharmacyCard(context, pharmacy))).toList(),
    ); 
  }

  Widget _buildPharmacyCard(BuildContext context, PharmacyEntity pharmacy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to pharmacy details or dashboard
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_mall_directory_outlined, color: Colors.blueGrey, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                pharmacy.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(pharmacy.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (pharmacy.address != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              pharmacy.address!,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (pharmacy.city != null)
                          Text(
                            pharmacy.city!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),

              Row(
                children: [
                   Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditPharmacyPage(pharmacy: pharmacy),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifier', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OnCallPage()),
                          );
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: const Text('Gardes', style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        label = 'Validé';
        break;
      case 'pending':
        color = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        label = 'En attente';
        break;
      case 'rejected':
        color = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        label = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
