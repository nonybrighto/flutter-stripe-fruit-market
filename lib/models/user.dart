class User {
  String id;
  String email;

  User({
    required this.id,
    required this.email,
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        email = json['email'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
      };
}
