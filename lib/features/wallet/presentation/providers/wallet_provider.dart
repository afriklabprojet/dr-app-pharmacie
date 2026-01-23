import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/wallet_data.dart';
import '../../../../core/providers/core_providers.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(apiClientProvider).dio);
});

final walletProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletData();
});
