const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
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

exports.createPaymentIntent = functions.https
    .onRequest(async (request, response) => {
      try {
        const {productId} = request.body;
        const customer = await _getCustomerFromRequest(request);
        const product = await _getProduct(productId);
        const stripeObject = {
          amount: product.amount * 100, // Use smallest currency unit (cent)
          currency: "USD",
          payment_method_types: ["card"],
          setup_future_usage: "off_session",
          customer: customer.stripeCustomerId,
          metadata: {
            productId,
            customerId: customer.id,
          },
        };
        if (request.body.paymentMethodId) {
          stripeObject.payment_method = request.body.paymentMethodId;
        }
        const paymentIntent = await stripe.paymentIntents.create(stripeObject);
        return response.status(200).send(paymentIntent);
      } catch (error) {
        functions.logger.error("intent create", error);
        return response.sendStatus(400);
      }
    });


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
