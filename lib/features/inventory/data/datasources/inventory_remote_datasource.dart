import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

abstract class InventoryRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<CategoryModel>> getCategories();
  Future<void> updateStock(int productId, int newQuantity);
  Future<void> updatePrice(int productId, double newPrice);
  Future<void> toggleAvailability(int productId);
  Future<ProductModel> addProduct(Map<String, dynamic> productData, {XFile? image});
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> productData, {XFile? image});
  Future<void> deleteProduct(int id);
  Future<CategoryModel> addCategory(String name, String? description);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final ApiClient apiClient;

  InventoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ProductModel>> getProducts() async {
    // Liste des produits
    final response = await apiClient.get('/pharmacy/inventory');

    return (response.data['data'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    // Liste des catégories
    final response = await apiClient.get('/pharmacy/inventory/categories');

    return (response.data['data'] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }

  @override
  Future<void> updateStock(int productId, int newQuantity) async {
    // Mise à jour du stock
    await apiClient.post(
      '/pharmacy/inventory/$productId/stock',
      data: {'quantity': newQuantity},
    );
  }

  @override
  Future<void> updatePrice(int productId, double newPrice) async {
    // Mise à jour du prix
    await apiClient.post(
      '/pharmacy/inventory/$productId/price',
      data: {'price': newPrice},
    );
  }

  @override
  Future<void> toggleAvailability(int productId) async {
    // Bascule de statut
    await apiClient.post('/pharmacy/inventory/$productId/toggle-status');
  }

  @override
  Future<ProductModel> addProduct(Map<String, dynamic> productData, {XFile? image}) async {
    // Ajout d'un nouveau produit avec gestion d'image
    // Conversion des booléens en entiers (1/0) pour Laravel Validation
    final Map<String, dynamic> safeData = Map.from(productData);
    if (safeData['requires_prescription'] is bool) {
      safeData['requires_prescription'] = safeData['requires_prescription'] ? 1 : 0;
    }

    dynamic data;
    if (image != null) {
      final bytes = await image.readAsBytes();
      data = FormData.fromMap({
        ...safeData,
        'image': MultipartFile.fromBytes(bytes, filename: image.name), 
      });
    } else {
      data = safeData;
    }

    final response = await apiClient.post(
      '/pharmacy/inventory',
      data: data,
    );
    return ProductModel.fromJson(response.data['data']);
  }

  @override
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> productData, {XFile? image}) async {
    final Map<String, dynamic> safeData = Map.from(productData);
    if (safeData['requires_prescription'] is bool) {
      safeData['requires_prescription'] = safeData['requires_prescription'] ? 1 : 0;
    }

    dynamic data;
    if (image != null) {
      final bytes = await image.readAsBytes();
      data = FormData.fromMap({
        ...safeData,
        'image': MultipartFile.fromBytes(bytes, filename: image.name),
      });
    } else {
      data = safeData;
    }

    final response = await apiClient.post(
      '/pharmacy/inventory/$id/update',
      data: data,
    );
    return ProductModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await apiClient.delete('/pharmacy/inventory/$id');
  }

  @override
  Future<CategoryModel> addCategory(String name, String? description) async {
    final response = await apiClient.post(
      '/pharmacy/inventory/categories',
      data: {
        'name': name,
        'description': description,
      },
    );
    return CategoryModel.fromJson(response.data['data']);
  }
}
