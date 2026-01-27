class WalletData {
  final double balance;
  final String currency;
  final double totalEarnings;
  final List<WalletTransaction> transactions;

  WalletData({
    required this.balance,
    required this.currency,
    required this.totalEarnings,
    required this.transactions,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      balance: double.parse(json['balance'].toString()),
      currency: json['currency'] ?? 'XOF',
      totalEarnings: double.parse(json['total_earnings'].toString()),
      transactions: (json['transactions'] as List)
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
    );
  }
}

class WalletTransaction {
  final int id;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String? description;
  final String? reference;
  final String? date;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    this.reference,
    this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      description: json['description'],
      reference: json['reference'],
      date: json['date'],
    );
  }
}

/// Paramètres de seuil de retrait
class WithdrawalSettings {
  final double threshold;
  final bool autoWithdraw;
  final bool hasPin;
  final bool hasMobileMoney;
  final bool hasBankInfo;

  WithdrawalSettings({
    required this.threshold,
    required this.autoWithdraw,
    this.hasPin = false,
    this.hasMobileMoney = false,
    this.hasBankInfo = false,
  });

  factory WithdrawalSettings.fromJson(Map<String, dynamic> json) {
    return WithdrawalSettings(
      threshold: (json['threshold'] as num?)?.toDouble() ?? 50000,
      autoWithdraw: json['auto_withdraw'] ?? false,
      hasPin: json['has_pin'] ?? false,
      hasMobileMoney: json['has_mobile_money'] ?? false,
      hasBankInfo: json['has_bank_info'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'threshold': threshold,
    'auto_withdraw': autoWithdraw,
    'has_pin': hasPin,
    'has_mobile_money': hasMobileMoney,
    'has_bank_info': hasBankInfo,
  };
}
