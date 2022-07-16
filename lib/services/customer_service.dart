import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe_payment/models/customer.dart';

class CustomerService {
  final _customerCollection =
      FirebaseFirestore.instance.collection("customers");
  createUser(Customer user) async {
    await _customerCollection.doc(user.id).set(user.toJson());
  }

  Future<Customer?> getAuthenticatedCustomer() async {
    final _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      final _customerSnapshot =
          await _customerCollection.doc(_currentUser.uid).get();
      return Customer.fromJson(
          {"id": _customerSnapshot.id, ..._customerSnapshot.data()!});
    }
    return null;
  }
}
