class Product {
  String id;
  String name;
  double amount;
  String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.amount,
    required this.imageUrl,
  });

  Product.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        amount = json['amount'],
        imageUrl = json['imageUrl'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'imageUrl': imageUrl,
      };
}
