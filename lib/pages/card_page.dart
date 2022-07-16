import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_payment/models/product.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';
import 'package:flutter_stripe_payment/services/customer_service.dart';
import 'package:flutter_stripe_payment/services/payment_service.dart';

class CardPage extends StatefulWidget {
  final Product productToPurchase;
  const CardPage({Key? key, required this.productToPurchase}) : super(key: key);

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool allowPayButtonPress = false;
  final controller = CardFormEditController();
  bool loading = false;
  bool _saveCard = false;
  PaymentService paymentService = PaymentService(
    authService: AuthService(
      customerService: CustomerService(),
    ),
  );

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        allowPayButtonPress = controller.details.complete == true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Page'),
      ),
      body: Column(
        children: [..._buildCardForm()],
      ),
    );
  }

  _buildCardForm() {
    return [
      CardFormField(
        controller: controller,
        style: CardFormStyle(
          borderColor: Colors.blueGrey,
          textColor: Colors.black,
          fontSize: 24,
          placeholderColor: Colors.blue,
        ),
      ),
      Row(
        children: [
          Checkbox(
              value: _saveCard,
              onChanged: (value) {
                setState(() {
                  _saveCard = value ?? false;
                });
              }),
          const Text('Save Ccard'),
        ],
      ),
      ElevatedButton(
        onPressed: allowPayButtonPress ? _handlePayButtonPressed : null,
        child: loading ? const CircularProgressIndicator() : const Text('Pay'),
      ),
    ];
  }

  _handlePayButtonPressed() async {
    try {
      setState(() {
        loading = true;
      });
      await paymentService.payWithCardField(
        productId: widget.productToPurchase.id,
        saveCard: _saveCard,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment successful")));
    } catch (error) {
      // error
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to make payment")));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}
