import 'package:flutter/material.dart';
import 'package:flutter_stripe_payment/models/customer.dart';
import 'package:flutter_stripe_payment/services/customer_service.dart';

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
      ),
      body: Column(children: [
        Text(_authenticatedCustomer != null
            ? _authenticatedCustomer!.email
            : 'loading..')
      ]),
    );
  }

  _setAuthenticatedUser() async {
    final customer = await _customerService.getAuthenticatedCustomer();
    setState(() {
      _authenticatedCustomer = customer;
    });
  }
}
