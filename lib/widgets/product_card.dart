import 'package:flutter/material.dart';
import 'package:flutter_stripe_payment/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool showPurchase;
  final Function({required Product product})? onPurchasePressed;

  const ProductCard({
    Key? key,
    required this.product,
    this.showPurchase = true,
    this.onPurchasePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(product.name),
            Text(product.amount.toString()),
            if (showPurchase)
              ElevatedButton(
                onPressed: () => onPurchasePressed!(product: product),
                child: const Text('Buy'),
              ),
          ],
        ),
      ),
    );
  }
}
