class Customer {
  String id;
  String email;

  Customer({
    required this.id,
    required this.email,
  });

  Customer.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        email = json['email'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
      };
}
