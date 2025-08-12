import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/screen/invoice/invoice_page.dart';
import 'package:myapp/screen/invoice/invoice_view_page.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  late String userId = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      print("User not logged in");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeLight = Color(0xFFF5E6D3);
    const Color coffeeTan = Color(0xFFD7B899);
    const Color coffeeAccent = Color(0xFF8D6E63);

    if (userId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: coffeeLight,
      appBar: AppBar(
        backgroundColor: coffeeLight,
        title: const Text(
          'Invoices',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: coffeeDark,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('invoices')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text("Error loading invoices");
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = snapshot.data!.docs;

          if (invoices.isEmpty) {
            return const Center(child: Text('No invoices found.'));
          }

          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final data = invoices[index].data() as Map<String, dynamic>;
              final invoiceId = invoices[index].id;

              return Card(
                color: coffeeLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoice Number + Delete Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Invoice #${data['invoiceNo'] ?? ''}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: coffeeAccent,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, invoiceId),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetail(
                        Icons.calendar_today,
                        "Date",
                        data['invoiceDate'] ?? '',
                        iconColor: coffeeDark,
                      ),
                      _buildDetail(
                        Icons.person,
                        "Customer",
                        data['customerName'] ?? '',
                        iconColor: coffeeDark,
                      ),
                      _buildDetail(
                        Icons.attach_money,
                        "Total",
                        "₹${(data['balanceAmount'] ?? 0).toStringAsFixed(2)}",
                        iconColor: coffeeDark,
                      ),
                      _buildDetail(
                        Icons.info_outline,
                        "Status",
                        data['status'] ?? 'Pending..',
                        valueColor:
                            (data['status'] ?? '').toLowerCase() == "paid"
                                ? Colors.green
                                : const Color.fromARGB(255, 226, 68, 44),
                        iconColor: coffeeDark,
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => Invoiceview(
                                      invoiceData: data,
                                      items: List<Map<String, dynamic>>.from(
                                        data['items'] ?? [],
                                      ),
                                      isEditable: true,
                                      documentId: invoiceId,
                                    ),
                              ),
                            );
                          },
                          child: Text(
                            "View Details",
                            style: TextStyle(
                              color: coffeeAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: coffeeDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Invoice", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InvoicePreviewPage()),
          );
        },
      ),
    );
  }

  Widget _buildDetail(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    Color? iconColor, // Added so we can pass theme color from build()
  }) {
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeText = Color(0xFF3E2723);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? coffeeDark),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: coffeeText,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? coffeeText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String invoiceId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Delete Invoice"),
            content: const Text(
              "Are you sure you want to delete this invoice?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('invoices')
                      .doc(invoiceId)
                      .delete();
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
