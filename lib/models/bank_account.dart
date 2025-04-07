class BankAccount {
  final int id;
  final String bankName;
  final String accountHolderName;
  final String? cardNumber;
  final String? iban;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    this.cardNumber,
    this.iban,
  });

  // Create a BankAccount from JSON data
  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: int.parse(json['id']),
      bankName: json['bank_name'],
      accountHolderName: json['account_holder_name'],
      cardNumber: json['card_number'],
      iban: json['iban'],
    );
  }

  // Convert BankAccount to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'card_number': cardNumber,
      'iban': iban,
    };
  }
} 