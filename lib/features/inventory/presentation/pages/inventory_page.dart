import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/inventory_provider.dart';
import '../providers/state/inventory_state.dart';
import '../widgets/add_product_sheet.dart'; 
import '../widgets/categories_management_sheet.dart';
import '../widgets/product_details_sheet.dart';
import 'scanner_page.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _scanBarcode() async {
    try {
      final String? res = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ScannerPage(),
        ),
      );

      if (res != null && res != '-1' && mounted) {
        final existingProduct = ref
            .read(inventoryProvider.notifier)
            .findProductByBarcode(res);

        if (existingProduct != null) {
          if (mounted) {
            _showUpdateStockDialog(context, existingProduct);
          }
        } else {
          if (mounted) {
            // OUVERTURE DE LA NOUVELLE MODALE PROFESSIONNELLE
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddProductSheet(scannedBarcode: res),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur scanner: $e')));
      }
    }
  }

  // ... (Garder _showUpdateStockDialog pour l'instant car c'est une petite popup)

  // ... (Supprimer l'ancienne méthode _showAddProductDialog qui n'est plus utilisée)


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUpdateStockDialog(BuildContext context, ProductEntity product) {
    final quantityController = TextEditingController(
      text: product.stockQuantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Mettre à jour le stock: ${product.name}'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nouvelle quantité',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null && newQuantity >= 0) {
                  ref
                      .read(inventoryProvider.notifier)
                      .updateStock(product.id, newQuantity);
                  Navigator.pop(context);
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    // Filter products based on search query
    final filteredProducts = state.products.where((product) {
      final query = state.searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();

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
                  // En-tête personnalisé
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final authState = ref.watch(authProvider);
                              final pharmacyName = authState.user?.pharmacies.isNotEmpty == true 
                                  ? authState.user!.pharmacies.first.name 
                                  : '';
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestion Stock',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                      fontSize: 28,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (pharmacyName.isNotEmpty)
                                    Text(
                                      pharmacyName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              );
                            },
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
                  const SizedBox(height: 16),
                  
                  // Barre de recherche et scanneur
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher un produit...',
                                hintStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.search, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              onChanged: (value) {
                                ref.read(inventoryProvider.notifier).search(value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: IconButton(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner, size: 24),
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const CategoriesManagementSheet(),
                              );
                            },
                            icon: const Icon(Icons.category_outlined, size: 24, color: Color(0xFF1E88E5)), // Hardcoded color to avoid const error with dynamic theme color
                            tooltip: 'Gérer les catégories',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                ],
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.status == InventoryStatus.loading &&
                      state.products.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }

                  if (state.status == InventoryStatus.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur: ${state.errorMessage}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .fetchProducts();
                            },
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

                  if (filteredProducts.isEmpty) {
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
                            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucun produit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre stock est vide ou aucun\nproduit ne correspond à la recherche.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      Color statusColor;
                      Color bgColor;
                      IconData statusIcon;
                      String statusLabel;

                      if (product.isOutOfStock) {
                        statusColor = const Color(0xFFC62828); // Red 800
                        bgColor = const Color(0xFFFFEBEE);
                        statusIcon = Icons.warning_rounded;
                        statusLabel = 'Rupture';
                      } else if (product.isLowStock) {
                        statusColor = const Color(0xFFE65100); // Orange 900
                        bgColor = const Color(0xFFFFF3E0);
                        statusIcon = Icons.warning_amber_rounded;
                        statusLabel = 'Faible';
                      } else {
                        statusColor = const Color(0xFF2E7D32); // Green 800
                        bgColor = const Color(0xFFE8F5E9);
                        statusIcon = Icons.check_circle_outline_rounded;
                        statusLabel = 'En Stock';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8D8D8D).withOpacity(0.1),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => ProductDetailsSheet(product: product),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icone de statut ou Image Produit
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: product.imageUrl != null 
                                          ? Border.all(color: Colors.grey.shade200, width: 1)
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: product.imageUrl != null
                                          ? Image.network(
                                              product.imageUrl!,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                debugPrint("ERREUR IMAGE PROJET: ${product.imageUrl} - $error");
                                                return Container(
                                                  color: Colors.red.shade50,
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.broken_image_rounded, color: Colors.indigo, size: 24),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / 
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: bgColor,
                                              alignment: Alignment.center,
                                              child: Icon(statusIcon, color: statusColor, size: 24),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: bgColor,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.description.isEmpty ? 'Aucune description' : product.description,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F7FA),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0, locale: 'fr_FR').format(product.price)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Qte: ',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '${product.stockQuantity}',
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddProductSheet(),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
