import 'package:flutter/material.dart';
import 'package:flutter_stripe_payment/models/product.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';
import 'package:flutter_stripe_payment/services/purchase_service.dart';
import 'package:flutter_stripe_payment/widgets/product_card.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({Key? key}) : super(key: key);

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
      ),
      body: Column(children: [
        FutureBuilder<List<Product>>(
          future: PurchaseService(authService: AuthService())
              .fetchCurrentCustomerPurchasedProducts(),
          initialData: const [],
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Expanded(
                  child: GridView.builder(
                itemCount: snapshot.data!.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: snapshot.data![index],
                    showPurchase: false,
                  );
                },
              ));
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ]),
    );
  }
}
