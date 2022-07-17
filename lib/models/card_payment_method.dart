class CardPaymentMethod {
  String id;
  String brand;
  int expiryMonth;
  int expiryYear;
  String last4;

  CardPaymentMethod({
    required this.id,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.last4,
  });

  CardPaymentMethod.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        brand = json['card']['brand'],
        expiryMonth = json['exp_month'],
        expiryYear = json['exp_year'],
        last4 = json['last4'];
}
