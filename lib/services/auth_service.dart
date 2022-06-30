import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe_payment/models/user.dart' as app;
import 'package:flutter_stripe_payment/services/user_service.dart';

class AuthService {
  UserService userService;

  AuthService({required this.userService});

  Future<void> signUp({required String email, required String password}) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if(user != null){
    await userService.createUser(app.User(id: user.uid, email: user.email!));
    }
  }
}
