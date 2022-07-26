const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2020-08-27",
});
admin.initializeApp();


exports.createStripeCustomer = functions.firestore
    .document("customers/{customerId}")
    .onCreate(async (snap, context) => {
      try {
        const newValue = snap.data();
        const customer = await stripe.customers.create({
          email: newValue.email,
        });
        await admin
            .firestore()
            .collection("customers")
            .doc(context.params.customerId)
            .update({
              stripeCustomerId: customer.id,
            });
      } catch (error) {
        functions.logger.error("Stripe customer ccreation error", error);
      }
    });

exports.createPaymentSheet = functions.https
    .onRequest(async (request, response) => {
      try {
        const {productId} = request.body;
        const customer = await _getCustomerFromRequest(request);
        const product = await _getProduct(productId);
        const stripeObject = {
          amount: product.amount * 100, // Use smallest currency unit (cent)
          currency: "USD",
          payment_method_types: ["card"],
          customer: customer.stripeCustomerId,
          metadata: {
            productId,
            customerId: customer.id,
          },
        };
        const ephemeralKey = await stripe.
            ephemeralKeys.create({customer: customer.stripeCustomerId},
                {apiVersion: "2020-08-27"},
            );
        const paymentIntent = await stripe.paymentIntents.create(stripeObject);
        return response.status(200).send({
          clientSecret: paymentIntent["client_secret"],
          ephemeralKey: ephemeralKey.secret,
        });
      } catch (error) {
        functions.logger.error("init payment sheet", error);
        return response.sendStatus(400);
      }
    });

exports.createPaymentIntent = functions.https
    .onRequest(async (request, response) => {
      try {
        const {productId, paymentMethodId, allowFutureUsage} = request.body;
        const customer = await _getCustomerFromRequest(request);
        const product = await _getProduct(productId);
        const stripeObject = {
          amount: product.amount * 100, // Use smallest currency unit (cent)
          currency: "USD",
          payment_method_types: ["card"],
          customer: customer.stripeCustomerId,
          metadata: {
            productId,
            customerId: customer.id,
          },
          ...(allowFutureUsage && {setup_future_usage: "off_session"}),
          ...(paymentMethodId && {payment_method: paymentMethodId}),
        };

        const paymentIntent = await stripe.paymentIntents.create(stripeObject);
        return response.status(200).send({
          clientSecret: paymentIntent["client_secret"],
        });
      } catch (error) {
        functions.logger.error("create payment intent", error);
        return response.sendStatus(400);
      }
    });


// used to charge a card without intercation from the customer.
// Suitable for cron jobs. For this example, it will still be triggered
// from the front end as a second alternative to making payment with saved card.

exports.chargeCardOffSession = functions.https
    .onRequest(async (request, response) => {
      try {
        const {productId} = request.body;
        const customer = await _getCustomerFromRequest(request);
        const product = await _getProduct(productId);
        const stripeObject = {
          amount: product.amount * 100, // Use smallest currency unit (cent)
          currency: "USD",
          customer: customer.stripeCustomerId,
          payment_method: request.body.paymentMethodId,
          off_session: true,
          confirm: true,
          metadata: {
            productId,
            customerId: customer.id,
          },
        };
        const paymentIntent = await stripe.paymentIntents.create(stripeObject);
        return response.status(200).send(paymentIntent);
      } catch (error) {
      // best to send a message to the customer letting them know
      // that their card was not charged
        functions.logger.error("intent create", error);
        return response.sendStatus(400);
      }
    });


exports.fetchCustomerCards = functions.https.onRequest(
    async (request, response) => {
      try {
        const customer = await _getCustomerFromRequest(request);
        const paymentMethods = await stripe.paymentMethods.list({
          customer: customer.stripeCustomerId,
          type: "card",
        });
        return response.status(200).send(paymentMethods.data);
      } catch (error) {
        console.log(error);
        functions.logger.error("Customer card error", error);
        return response.sendStatus(400);
      }
    },
);

exports.deletePaymentMethod = functions.https.onRequest(
    async (request, response) => {
      try {
        await stripe.paymentMethods.detach(request.body.paymentMethodId);
        return response.sendStatus(200);
      } catch (error) {
        console.log(error);
        functions.logger.info("delete payment method", {error: error});
        return response.sendStatus(400);
      }
    },
);


exports.stripeWebhook = functions.https
    .onRequest(async (request, response) => {
      try {
        let event;
        try {
          event = stripe.webhooks.constructEvent(
              request.rawBody,
              request.headers["stripe-signature"] || [],
              process.env.STRIPE_WEBHOOK_SECRET,
          );
        } catch (error) {
          functions.logger.info("stripe webhook verification error",
              error);
          return response.sendStatus(400);
        }
        if (event.type === "payment_intent.succeeded") {
          const {customerId, productId} = request.body.data.object.metadata;
          await _savePurchase(customerId, productId);
        }
        return response.sendStatus(200);
      } catch (error) {
        functions.logger.error("stripe webhook error", error);
        return response.sendStatus(400);
      }
    });


/**
 * Get product from firestore with Id
 * @param {string} productId Id of product
*/
async function _getProduct(productId) {
  const documentSnapshot = await admin
      .firestore()
      .collection("products")
      .doc(productId).get();

  return {id: documentSnapshot.id, ...documentSnapshot.data()};
}
/**
 * Get the customer throught the firebase id tokenn sent inn the request header
 * @param {object} request firebase id token of user gotten from client side
*/
async function _getCustomerFromRequest(request) {
  const idToken = request.get("Authorization").split("Bearer ")[1];
  const verifiedToken = await admin.auth().verifyIdToken(idToken);
  const documentSnapshot = await admin
      .firestore()
      .collection("customers")
      .doc(verifiedToken.uid).get();
  return {id: documentSnapshot.id, ...documentSnapshot.data()};
}

/**
 *
 * @param {string} customerId firebase id of the customer
 * that made the purchase.
 * @param {string} productId product that was purchased by the customer.
 */
async function _savePurchase(customerId, productId) {
  const product = await _getProduct(productId);
  await admin
      .firestore()
      .collection("purchases").add({
        customerId,
        product,
        datePurchased: admin.firestore.FieldValue.serverTimestamp(),
      });
}
