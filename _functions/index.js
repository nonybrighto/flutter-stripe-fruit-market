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
            .collection("customer")
            .doc(context.params.customerId)
            .update({
              stripeCustomerId: customer.id,
            });
      } catch (error) {
        functions.logger.info("error creating stripe customer", {error: error});
      }
    });
