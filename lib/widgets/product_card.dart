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
      elevation: 0,
      color: const Color(0XFFf3f3f3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: NetworkImage(product.imageUrl),
                    ),
                    color: Colors.white),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(product.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$' + product.amount.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (showPurchase)
                  TextButton(
                    onPressed: () => onPurchasePressed!(product: product),
                    child: const Text('Buy'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
