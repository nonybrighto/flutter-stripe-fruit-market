import 'package:flutter/material.dart';
import 'package:flutter_stripe_payment/models/customer.dart';
import 'package:flutter_stripe_payment/models/product.dart';
import 'package:flutter_stripe_payment/pages/card_page.dart';
import 'package:flutter_stripe_payment/pages/purchases_page.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';
import 'package:flutter_stripe_payment/services/customer_service.dart';
import 'package:flutter_stripe_payment/services/payment_service.dart';
import 'package:flutter_stripe_payment/services/product_service.dart';
import 'package:flutter_stripe_payment/widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Customer? _authenticatedCustomer;
  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    _setAuthenticatedUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
              icon: const Icon(Icons.inventory),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PurchasesPage()));
              })
        ],
      ),
      body: Column(children: [
        Text(_authenticatedCustomer != null
            ? _authenticatedCustomer!.email
            : 'loading..'),
        FutureBuilder<List<Product>>(
          future: ProductService().fetchProducts(),
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
                    onPurchasePressed: _onPurchasePressed,
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

  _setAuthenticatedUser() async {
    final customer = await _customerService.getAuthenticatedCustomer();
    setState(() {
      _authenticatedCustomer = customer;
    });
  }

  _onPurchasePressed({required Product product}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Payment Option'),
            children: [
              SimpleDialogOption(
                child: const Text('Payment Sheet'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  //show payment sheet
                  try {
                    final paymentService = PaymentService(
                        authService:
                            AuthService(customerService: CustomerService()));
                    await paymentService.payWithPaymentSheet(
                        productId: product.id);
                  } catch (error) {
                    print(error);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Failed to create payment sheet"),
                    ));
                  }
                },
              ),
              SimpleDialogOption(
                child: const Text('Form Payment'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CardPage(productToPurchase: product),
                  ));
                },
              ),
            ],
          );
        });
  }
}
