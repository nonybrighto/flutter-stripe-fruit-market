import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_payment/models/card_payment_method.dart';
import 'package:flutter_stripe_payment/models/product.dart';
import 'package:flutter_stripe_payment/pages/home_page.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';
import 'package:flutter_stripe_payment/services/customer_service.dart';
import 'package:flutter_stripe_payment/services/payment_service.dart';
import 'package:flutter_stripe_payment/widgets/base_view.dart';
import 'package:loader_overlay/loader_overlay.dart';

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
  late BuildContext _parentContext;
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
    return LoaderOverlay(
      useDefaultLoading: false,
      overlayWidget: const Center(child: CircularProgressIndicator()),
      child: BaseView(
        title: 'title',
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildCardForm(),
              const SizedBox(height: 20),
              ..._buildSavedCardsDisplay(),
            ],
          ),
        ),
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
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12) // <-- Radius
              ),
          minimumSize: const Size.fromHeight(
              50), // fromHeight use double.infinity as width and 40 is the height
        ),
        onPressed: allowPayButtonPress ? _handlePayButtonPressed : null,
        child: loading ? const CircularProgressIndicator() : const Text('Pay'),
      ),
    ];
  }

  _buildSavedCardsDisplay() {
    return [
      const Text(
        'Use Saved cards',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
      const SizedBox(
        height: 20,
      ),
      FutureBuilder<List<CardPaymentMethod>>(
        future: paymentService.fetchCustomerCard(),
        builder: (context, snapshot) {
          _parentContext = context;
          final cardPaymentMethods = snapshot.data;
          if (!snapshot.hasData) {
            return Center(
              child: snapshot.hasError
                  ? const Text('Could not load cards')
                  : const CircularProgressIndicator(),
            );
          } else if (cardPaymentMethods!.isEmpty) {
            return const Center(
              child: Text('No saved card'),
            );
          }

          return ListView.builder(
              shrinkWrap: true,
              itemCount: cardPaymentMethods.length,
              itemBuilder: ((context, index) {
                final card = cardPaymentMethods[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: const BoxDecoration(
                      color: Color(0XFFf8f8f8),
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: ListTile(
                    title: Text(
                      '**** **** **** ${card.last4}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('${card.expiryMonth}/${card.expiryYear}'),
                    onTap: () => _handleSavedCardButtonPressed(
                        cardPaymentMethods[index]),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () =>
                          _handleDeleteButtonPressed(cardPaymentMethods[index]),
                    ),
                  ),
                );
              }));
        },
      )
    ];
  }

  _handleDeleteButtonPressed(CardPaymentMethod cardPaymentMethod) async {
    try {
      _parentContext.loaderOverlay.show();
      await paymentService.deletePaymentMethod(cardPaymentMethod);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Card removed successfully")));
      setState(() {}); // Used to remove the deleted card from display
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to remove card")));
    } finally {
      _parentContext.loaderOverlay.hide();
    }
  }

  _handleSavedCardButtonPressed(CardPaymentMethod cardPaymentMethod) async {
    try {
      _parentContext.loaderOverlay.show();
      await paymentService.payWithSavedCard(
          productId: widget.productToPurchase.id,
          cardPaymentMethod: cardPaymentMethod);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment successful")));
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomePage()));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to make payment")));
    } finally {
      _parentContext.loaderOverlay.hide();
    }
  }

  _handlePayButtonPressed() async {
    try {
      setState(() {
        loading = true;
      });
      await paymentService.payWithCardField(
        productId: widget.productToPurchase.id,
        allowFutureUsage: _saveCard,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment successful")));
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomePage()));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to make payment")));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}
