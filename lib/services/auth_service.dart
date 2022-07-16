import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe_payment/models/customer.dart';
import 'package:flutter_stripe_payment/services/customer_service.dart';

class AuthService {
  CustomerService? customerService;

  AuthService({this.customerService});

  Future<void> signUp({required String email, required String password}) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      await customerService
          ?.createUser(Customer(id: user.uid, email: user.email!));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  Future<String> getAuthorizedUserToken() async {
    if (FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.getIdToken();
    }
    return '';
  }

  User getCurrentUser() {
    // user will always be present since activities happen after sign in.
    return FirebaseAuth.instance.currentUser!;
  }
}
