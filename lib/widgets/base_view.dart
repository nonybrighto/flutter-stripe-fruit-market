import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe_payment/pages/purchases_page.dart';

class BaseView extends StatelessWidget {
  final String title;
  final bool isLoading;
  final bool hasError;
  final Widget child;

  const BaseView({
    Key? key,
    required this.title,
    this.isLoading = false,
    this.hasError = false,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.inventory),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PurchasesPage()));
              })
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (hasError) {
      return const Center(
        child: Text('Error while loading content'),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      );
    }
  }
}
