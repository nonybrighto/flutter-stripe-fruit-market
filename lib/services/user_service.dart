import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe_payment/models/user.dart';

class UserService {

     final _userCollection = FirebaseFirestore.instance.collection("users");
     createUser(User user) async {
        await _userCollection.doc(user.id).set(user.toJson());
     }
     
}