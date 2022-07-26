import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_payment/constants/constants.dart';
import 'package:flutter_stripe_payment/models/card_payment_method.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';

class PaymentService {
  AuthService authService;

  PaymentService({required this.authService});

  payWithPaymentSheet({productId}) async {
    final data = await _createPaymentSheet(
      productId: productId,
    );
    final authenticatedCustomer =
        await authService.customerService?.getAuthenticatedCustomer();
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: data['clientSecret'],
        customerEphemeralKeySecret: data['ephemeralKey'],
        merchantDisplayName: 'Fruit Market',
        customerId: authenticatedCustomer!.stripeCustomerId,
        primaryButtonColor: Colors.orange,
        // billingDetails: billingDetails,
        testEnv: true,
        merchantCountryCode: 'US',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  payWithCardField({productId, allowFutureUsage = false}) async {
    try {
      final authenticatedCustomer =
          await authService.customerService?.getAuthenticatedCustomer();
      final paymentIntent = await _createPaymentIntent(
        productId: productId,
        allowFutureUsage: allowFutureUsage,
      );
      final billingDetails = BillingDetails(
        email: authenticatedCustomer!.email,
      );

      await Stripe.instance.confirmPayment(
        paymentIntent['clientSecret'],
        PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
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
      // method 1
      // comment out method one and uncomment method 2 to rey it out
      final paymentIntent = await _createPaymentIntent(
        productId: productId,
        cardPaymentMethod: cardPaymentMethod,
      );
      await Stripe.instance.confirmPayment(
          paymentIntent['clientSecret'],
          PaymentMethodParams.cardFromMethodId(
            paymentMethodData: PaymentMethodDataCardFromMethod(
              paymentMethodId: cardPaymentMethod.id,
            ),
          ));

      // method 2
      // This method creates a payment intent that charges the saved card without
      // needing to confirm payment from the client. This is suitable for cron
      // jobs (tasks that don't require the user to be actively making use of the application when they occur)

      // await chargeCardOffSession(
      //   productId: productId,
      //   cardPaymentMethod: cardPaymentMethod,
      // );
    } catch (error) {
      throw Exception('Failed to make payment');
    }
  }

  Future<Map<String, dynamic>> chargeCardOffSession(
      {required String productId, CardPaymentMethod? cardPaymentMethod}) async {
    final userToken = await authService.getAuthorizedUserToken();
    Response response =
        await Dio(BaseOptions(headers: {'Authorization': 'Bearer $userToken'}))
            .post("$apiBaseUrl/chargeCardOffSession", data: {
      'productId': productId,
      'paymentMethodId': cardPaymentMethod?.id
    });
    return response.data;
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required String productId,
    CardPaymentMethod? cardPaymentMethod,
    bool allowFutureUsage = false,
  }) async {
    final userToken = await authService.getAuthorizedUserToken();
    Response response =
        await Dio(BaseOptions(headers: {'Authorization': 'Bearer $userToken'}))
            .post("$apiBaseUrl/createPaymentIntent", data: {
      'productId': productId,
      'paymentMethodId': cardPaymentMethod?.id,
      'allowFutureUsage': allowFutureUsage
    });
    return response.data;
  }

  Future<Map<String, dynamic>> _createPaymentSheet({
    required String productId,
  }) async {
    final userToken = await authService.getAuthorizedUserToken();
    Response response =
        await Dio(BaseOptions(headers: {'Authorization': 'Bearer $userToken'}))
            .post("$apiBaseUrl/createPaymentSheet", data: {
      'productId': productId,
    });
    return response.data;
  }
}
