const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
admin.initializeApp();


exports.createStripeCustomer = functions.firestore
    .document("customers/{customerId}")
    .onCreate(async (snap, context) => {
      try {
        console.log("Key");
        console.log(process.env.STRIPE_SECRET_KEY);
        functions.
            logger.
            info("secrete", {secret: process.env.STRIPE_SECRET_KEY});
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
        functions.logger.info("error creating stripe customer", {error: error});
      }
    });

exports.createPaymentIntent = functions.https
    .onRequest(async (request, response) => {
      try {
        const {productId} = request.body;
        functions.logger.info("body", {body: request.body});
        const customer = await _getCustomerFromRequest(request);
        functions.logger.info("intent create customer", {customer: customer});
        const product = await _getProduct(productId);
        functions.logger.info("intent create producct", {product: product});

        const stripeObject = {
          amount: product.amount * 100, // Use smallest currency unit.
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
        functions.logger.info("intent create", {error: error});
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
  functions.logger.info("token", {idToken: idToken});
  functions.
      logger.info("intent id token", {token: idToken});

  const verifiedToken = await admin.auth().verifyIdToken(idToken);
  const documentSnapshot = await admin
      .firestore()
      .collection("customers")
      .doc(verifiedToken.uid).get();
  return {id: documentSnapshot.id, ...documentSnapshot.data()};
}
