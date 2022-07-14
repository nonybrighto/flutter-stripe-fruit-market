import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe_payment/models/product.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';

class PurchaseService {
  AuthService authService;

  PurchaseService({required this.authService});

  final _purchaseCollection =
      FirebaseFirestore.instance.collection("purchases");

  Future<List<Product>> fetchCurrentCustomerPurchasedProducts() async {
    final user = authService.getCurrentUser();

    final QuerySnapshot<Map<String, dynamic>> purchasesSnapshot =
        await _purchaseCollection
            .where('customerId', isEqualTo: user.uid)
            .orderBy('datePurchased', descending: true)
            .get();
    final products = purchasesSnapshot.docs
        .map((purchase) => Product.fromJson(purchase.data()['product']))
        .toList();
    return products;
  }
}
