import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/notifications/presentation/providers/notifications_provider.dart';
import '../providers/order_list_provider.dart';
import '../widgets/order_card.dart';
import '../providers/state/order_list_state.dart';
import 'order_details_page.dart';

class OrdersListPage extends ConsumerWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 16, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Header personnalisé
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           'Mes Commandes',
                           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                             fontWeight: FontWeight.w800,
                             color: Colors.black87,
                             letterSpacing: -0.5,
                             fontSize: 28,
                           ),
                         ),
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
                   ),
                   const SizedBox(height: 24),
                   // Filtres défilants
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     child: Row(
                       children: [
                         _FilterChip(
                           label: 'Toutes',
                           isActive: state.activeFilter == 'all',
                           onTap: () =>
                               ref.read(orderListProvider.notifier).setFilter('all'),
                         ),
                         const SizedBox(width: 12),
                         _FilterChip(
                           label: 'En attente',
                           isActive: state.activeFilter == 'pending',
                           onTap: () =>
                               ref.read(orderListProvider.notifier).setFilter('pending'),
                         ),
                         const SizedBox(width: 12),
                         _FilterChip(
                           label: 'Confirmées',
                           isActive: state.activeFilter == 'confirmed',
                           onTap: () => ref
                               .read(orderListProvider.notifier)
                               .setFilter('confirmed'),
                         ),
                         const SizedBox(width: 12),
                         _FilterChip(
                           label: 'Prêtes',
                           isActive: state.activeFilter == 'ready',
                           onTap: () =>
                               ref.read(orderListProvider.notifier).setFilter('ready'),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                ],
              ),
            ),
            
            // Corps de la liste
            Expanded(
              child: _buildBody(context, state, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderListState state, WidgetRef ref) {
    if (state.status == OrderStatus.loading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    if (state.status == OrderStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Une erreur est survenue',
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(orderListProvider.notifier).fetchOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune commande',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de commandes\ncorrespondant à ce filtre.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      onRefresh: () => ref.read(orderListProvider.notifier).fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return OrderCard(
            order: order,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailsPage(order: order),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: isActive 
              ? Border.all(color: Colors.transparent)
              : Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
