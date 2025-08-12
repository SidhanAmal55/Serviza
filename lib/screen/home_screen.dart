import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  Future<int> _getCustomerCount() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('customers')
            .get();
    return snapshot.size;
  }

  Future<int> _getInvoiceCount() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('invoices')
            .get();
    return snapshot.size;
  }

  Future<double> _getTotalBalanceAmount() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('invoices')
            .where('status', isNotEqualTo: 'Paid')
            .get();

    double totalBalance = 0;
    for (var doc in snapshot.docs) {
      totalBalance += ((doc.data()['balanceAmount'] ?? 0) as num).toDouble();
    }
    return totalBalance;
  }

  Future<double> _getPaidBalanceAmount() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('invoices')
            .where('status', isEqualTo: 'Paid')
            .get();

    double totalPaid = 0;
    for (var doc in snapshot.docs) {
      totalPaid += ((doc.data()['balanceAmount'] ?? 0) as num).toDouble();
    }
    return totalPaid;
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color coffeeCream = Color(0xFFF5E6D3);
    const Color coffeeBrown = Color(0xFF6F4E37);
    const Color coffeeCaramel = Color(0xFFD2B48C);
    const Color coffeeDark = Color(0xFF3E2723);
    const Color coffeeGreen = Color(0xFF4E7C50);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: coffeeDark,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent, // Let gradient show
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                coffeeCream, // Light coffee cream
                coffeeBrown, // Deep coffee brown
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              coffeeCream, // Light coffee cream
              coffeeBrown, // Deep coffee brown
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Object?>>(
            future: Future.wait([
              _getInvoiceCount(),
              _getCustomerCount(),
              _getTotalBalanceAmount(),
              _getPaidBalanceAmount(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('No data available'));
              }

              int totalInvoices = snapshot.data![0] as int;
              int totalCustomers = snapshot.data![1] as int;
              double totalBalance = snapshot.data![2] as double;
              double totalPaid = snapshot.data![3] as double;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    _buildDashboardCard(
                      icon: Icons.receipt_long,
                      title: "Total Invoices",
                      value: "$totalInvoices",
                      color: coffeeDark,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildDashboardCard(
                      icon: Icons.people,
                      title: "Customers",
                      value: "$totalCustomers",
                      color: coffeeCaramel,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildDashboardCard(
                      icon: Icons.pending_actions,
                      title: "Pending Balance",
                      value: "₹${totalBalance.toStringAsFixed(2)}",
                      color: Colors.red.shade700,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildDashboardCard(
                      icon: Icons.paid_outlined,
                      title: "Paid Amount",
                      value: "₹${totalPaid.toStringAsFixed(2)}",
                      color: coffeeGreen,
                      onTap: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
