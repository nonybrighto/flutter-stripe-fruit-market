import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_payment/models/card_payment_method.dart';
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
        children: [..._buildCardForm(), ..._buildSavedCardsDisplay()],
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
          const Text('Save Card'),
        ],
      ),
      ElevatedButton(
        onPressed: allowPayButtonPress ? _handlePayButtonPressed : null,
        child: loading ? const CircularProgressIndicator() : const Text('Pay'),
      ),
    ];
  }

  _buildSavedCardsDisplay() {
    return [
      const Text('Use Saved cards'),
      FutureBuilder<List<CardPaymentMethod>>(
        initialData: const [],
        future: paymentService.fetchCustomerCard(),
        builder: (context, builder) {
          final cardPaymentMethods = builder.data;
          return ListView.builder(
              shrinkWrap: true,
              itemCount: cardPaymentMethods!.length,
              itemBuilder: ((context, index) {
                final card = cardPaymentMethods[index];
                return ListTile(
                  title: Text('**** **** **** ${card.last4}'),
                  subtitle: Text('${card.expiryMonth}/${card.expiryYear}'),
                  onTap: () =>
                      _handleSavedCardButtonPressed(cardPaymentMethods[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        _handleDeleteButtonPressed(cardPaymentMethods[index]),
                  ),
                );
              }));
        },
      )
    ];
  }

  _handleDeleteButtonPressed(CardPaymentMethod cardPaymentMethod) async {
    try {
      setState(() {
        loading = true;
      });
      await paymentService.deletePaymentMethod(cardPaymentMethod);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Card removed successfully")));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to remove card")));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  _handleSavedCardButtonPressed(CardPaymentMethod cardPaymentMethod) async {
    try {
      setState(() {
        loading = true;
      });
      await paymentService.payWithSavedCard(
          productId: widget.productToPurchase.id,
          cardPaymentMethod: cardPaymentMethod);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment successful")));
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to make payment")));
    } finally {
      setState(() {
        loading = false;
      });
    }
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
