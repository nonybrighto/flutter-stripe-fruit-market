import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_payment/constants/constants.dart';
import 'package:flutter_stripe_payment/models/card_payment_method.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';

class PaymentService {
  AuthService authService;

  PaymentService({required this.authService});

  Future<Map<String, dynamic>> createPaymentIntent(
      {required String productId, CardPaymentMethod? cardPaymentMethod}) async {
    final userToken = await authService.getAuthorizedUserToken();
    Response response =
        await Dio(BaseOptions(headers: {'Authorization': 'Bearer $userToken'}))
            .post("$apiBaseUrl/createPaymentIntent", data: {
      'productId': productId,
      'paymentMethodId': cardPaymentMethod?.id
    });
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
    await Stripe.instance.presentPaymentSheet();
  }

  payWithCardField({productId, saveCard = false}) async {
    try {
      final authenticatedCustomer =
          await authService.customerService?.getAuthenticatedCustomer();
      final paymentIntent = await createPaymentIntent(productId: productId);
      final billingDetails = BillingDetails(
        email: authenticatedCustomer!.email,
      );

      await Stripe.instance.confirmPayment(
        paymentIntent['client_secret'],
        PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
          options: PaymentMethodOptions(
            setupFutureUsage:
                saveCard ? PaymentIntentsFutureUsage.OffSession : null,
          ),
        ),
      );
    } catch (error) {
      throw Exception('Failed to make payment');
    }
  }

  Future<List<CardPaymentMethod>> fetchCustomerCard() async {
    final userToken = await authService.getAuthorizedUserToken();
    Response response =
        await Dio(BaseOptions(headers: {'Authorization': 'Bearer $userToken'}))
            .get("$apiBaseUrl/fetchCustomerCards");
    print(response);
    print(response.data);
    final cards = response.data.map<CardPaymentMethod>((intent) {
      final card = intent['card'];
      return CardPaymentMethod(
        id: intent['id'],
        brand: card['brand'],
        expiryMonth: card['exp_month'],
        expiryYear: card['exp_year'],
        last4: card['last4'],
      );
    }).toList();
    return cards;
  }

  deletePaymentMethod(CardPaymentMethod cardPaymentMethod) async {
    try {
      final userToken = await authService.getAuthorizedUserToken();
      await Dio(
        BaseOptions(headers: {'Authorization': 'Bearer $userToken'}),
      ).post(
        "$apiBaseUrl/deletePaymentMethod",
        data: {"paymentMethodId": cardPaymentMethod.id},
      );
    } catch (error) {
      throw Exception('Failed to delete payment method');
    }
  }

  payWithSavedCard(
      {required String productId,
      required CardPaymentMethod cardPaymentMethod}) async {
    try {
      final paymentIntent = await createPaymentIntent(
        productId: productId,
        cardPaymentMethod: cardPaymentMethod,
      );
      await Stripe.instance.confirmPayment(
          paymentIntent['client_secret'],
          PaymentMethodParams.cardFromMethodId(
            paymentMethodData: PaymentMethodDataCardFromMethod(
              paymentMethodId: cardPaymentMethod.id,
            ),
          ));
    } catch (error) {
      throw Exception('Failed to make payment');
    }
  }
}
