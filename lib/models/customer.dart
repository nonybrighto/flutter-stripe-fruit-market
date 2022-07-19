class Customer {
  String id;
  String email;
  String? stripeCustomerId;

  Customer({
    required this.id,
    required this.email,
    this.stripeCustomerId,
  });

  Customer.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        email = json['email'],
        stripeCustomerId = json['stripeCustomerId'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'stripeCustomerId': stripeCustomerId,
      };
}
