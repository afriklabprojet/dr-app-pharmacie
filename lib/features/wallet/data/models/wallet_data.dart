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
