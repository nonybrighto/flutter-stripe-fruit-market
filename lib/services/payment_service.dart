import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_payment/constants/constants.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';

class PaymentService {
  AuthService authService;

  PaymentService({required this.authService});

  Future<Map<String, dynamic>> createPaymentIntent({productId}) async {
    final userToken = await authService.getAuthorizedUserToken();
    Response response =
        await Dio(BaseOptions(headers: {'Authorization': 'Bearer $userToken'}))
            .post("$apiBaseUrl/createPaymentIntent",
                data: {'productId': productId});
    return response.data;
  }

  payWithPaymentSheet({productId}) async {
    final paymentIntent = await createPaymentIntent(productId: productId);
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        // Main params
        paymentIntentClientSecret: paymentIntent['client_secret'],
        merchantDisplayName: 'Flutter Stripe Payment',
        // Customer params
        customerId: paymentIntent['customer'],
        // customerEphemeralKeySecret: data['ephemeralKey'],
        // Extra params
        applePay: true,
        googlePay: true,
        primaryButtonColor: Colors.redAccent,
        // billingDetails: billingDetails,
        testEnv: true,
        merchantCountryCode: 'US',
      ),
    );
    print('Init done');
    await Stripe.instance.presentPaymentSheet();
    print('Init end');
  }
}
