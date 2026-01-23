import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // En-tête personnalisé
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Finance & Gains',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                      fontSize: 28,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 28),
                          onPressed: () => ref.refresh(walletProvider),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Consumer(
                            builder: (context, ref, child) {
                              final unreadCount = ref.watch(unreadNotificationCountProvider);
                              return Badge(
                                isLabelVisible: unreadCount > 0,
                                backgroundColor: Colors.redAccent,
                                smallSize: 10,
                                label: unreadCount > 0 ? null : null,
                                child: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 28),
                              );
                            },
                          ),
                          onPressed: () => context.push('/notifications'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

            Expanded(
              child: walletAsync.when(
                data: (wallet) => SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(context, wallet),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                            context,
                            'Total Ventes', 
                            wallet.totalEarnings, 
                            const Color(0xFF2E7D32), // Green
                            Icons.monetization_on_outlined
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            context,
                            'Transactions', 
                            wallet.transactions.length.toDouble(), 
                            const Color(0xFF1565C0), // Blue
                            Icons.receipt_long_outlined,
                            isCurrency: false
                          )),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Historique récent',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.5
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (wallet.transactions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8D8D8D).withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50], // Fond très léger pour l'icône
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.receipt_long_rounded, size: 32, color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune transaction récente', 
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vos mouvements financiers apparaîtront ici.', 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wallet.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = wallet.transactions[index];
                            final isCredit = tx.type == 'credit';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8D8D8D).withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  tx.description ?? 'Transaction',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700, 
                                    fontSize: 16
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (tx.reference != null) 
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'REF: ${tx.reference}',
                                            style: TextStyle(
                                              fontSize: 10, 
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600
                                            )
                                          ),
                                        ),
                                      Text(
                                        tx.date ?? '',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Text(
                                  '${isCredit ? '+' : '-'} ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(tx.amount)} FCFA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                    ],
                  ),
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange[300]),
                      const SizedBox(height: 16),
                      Text('Une erreur est survenue', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(err.toString().length > 50 ? '${err.toString().substring(0, 50)}...' : err.toString(), style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(walletProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, dynamic wallet) {
    // Calcul de couleurs plus douces et professionnelles basées sur la couleur primaire
    final primary = Theme.of(context).primaryColor;
    final deepPrimary = Color.lerp(primary, const Color(0xFF202020), 0.3) ?? primary;
    final softPrimary = Color.lerp(primary, Colors.white, 0.1) ?? primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        // Dégradé plus subtil et profond pour un look "Finance Premium"
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepPrimary,
            softPrimary,
          ],
          stops: const [0.2, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: deepPrimary.withOpacity(0.25), // Ombre moins saturée
            blurRadius: 30, // Plus diffus
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), // Transparence plus subtile
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)), // Bordure fine
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wallet_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Solde Disponible',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 13, 
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded, 
                  color: Colors.white.withOpacity(0.9), 
                  size: 18
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Mise en valeur du montant (La star)
          Text(
            NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0, locale: 'fr_FR').format(wallet.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40, // Plus grand
              fontWeight: FontWeight.w700, // Moins gras (w800 -> w700) pour plus d'élégance
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676), // Point vert vif pour "Live"
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mis à jour à l\'instant',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, double value, Color color, IconData icon, {bool isCurrency = true, String period = 'Ce mois-ci'}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D8D8D).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isCurrency 
              ? NumberFormat.compactCurrency(symbol: '', decimalDigits: 0).format(value)
              : value.toInt().toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            title, 
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}

