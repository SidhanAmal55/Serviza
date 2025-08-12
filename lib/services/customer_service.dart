import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';

class CustomerService {
  /// Get reference to a user's customer collection
  static CollectionReference getUserCustomerCollection(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('customers');
  }

  /// Add new customer
  static Future<void> addCustomer(String userId, Customer customer) async {
    final docRef = getUserCustomerCollection(userId).doc();
    final newCustomer = customer.copyWith(id: docRef.id); // update ID in model
    await docRef.set(newCustomer.toMap());
  }

  /// Update existing customer
  static Future<void> updateCustomer(String userId, String id, Customer customer) async {
    final docRef = getUserCustomerCollection(userId).doc(id);
    await docRef.update(customer.toMap());
  }

  /// Get all customers (real-time stream)
  static Stream<List<Customer>> getAllCustomers(String userId) {
    return getUserCustomerCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      }).toList();
    });
  }

  /// Get customer by ID
  static Future<Customer?> getCustomerById(String userId, String id) async {
    final doc = await getUserCustomerCollection(userId).doc(id).get();
    if (doc.exists) {
      return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);

    }
    return null;
  }
  static Stream<List<Customer>> streamCustomers() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('customers')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  /// Delete customer by ID
  static Future<void> deleteCustomer(String userId, String id) async {
    await getUserCustomerCollection(userId).doc(id).delete();
  }

  /// Search by vehicle number (optional field)
  static Future<List<Customer>> searchByVehicleNumber(
      String userId, String vehicleNumber) async {
    final querySnapshot = await getUserCustomerCollection(userId)
        .where('vehicleNumber', isEqualTo: vehicleNumber)
        .get();

    return querySnapshot.docs.map((doc) {
      return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);

    }).toList();
  }
}
