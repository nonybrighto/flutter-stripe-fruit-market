import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe_payment/models/product.dart';

class ProductService {
  final _productCollection = FirebaseFirestore.instance.collection("products");

  Future<List<Product>> fetchProducts() async {
    final QuerySnapshot<Map<String, dynamic>> productSnapshot =
        await _productCollection.get();
    final products = productSnapshot.docs
        .map((product) =>
            Product.fromJson({'id': product.id, ...product.data()}))
        .toList();
    return products;
  }
}
