import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() {
  Stripe.publishableKey =
      "pk_test_51I1PjoAAsS1Q02LJfqHCjbyDtfIU2IUiWz7GIJlTIkUjRrPCNJsOfBDSjPql58gHPXURblhNfkIcUv4HzpwVKNGl00av354vgu";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          CardField(
            onCardChanged: (card) {
              print(card);
            },
          ),
          TextButton(
            onPressed: () async {
              // create payment method
              try {
                print('Button pressed');
                final paymentMethod = await Stripe.instance.createPaymentMethod(
                    const PaymentMethodParams.card(
                        paymentMethodData: PaymentMethodData()));
                print(paymentMethod);
              } catch (error) {
                print(error);
              }
            },
            child: Text('pay'),
          )
        ],
      ),
    );
  }
}
