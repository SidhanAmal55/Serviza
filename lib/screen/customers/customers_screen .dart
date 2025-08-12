import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/screen/customers/customer_add_edit_screen.dart';
import '../../models/customer_model.dart';
import 'package:myapp/services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool searchTriggered = false;

  Widget _buildDetail(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    Color? iconColor,
  }) {
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeText = Color(0xFF3E2723);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor ?? coffeeDark),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: coffeeText,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: TextStyle(
                color: valueColor ?? coffeeText.withOpacity(0.85),
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color coffeeLight = Color(0xFFF5E6D3);
    const Color coffeeBrown = Color(0xFF6F4E37);
    const Color coffeeDark = Color(0xFF3E2723);
    const Color coffeeAccent = Color(0xFFD2B48C);

    return Scaffold(
      backgroundColor: coffeeLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by name, invoice no or contact",
                        prefixIcon: Icon(Icons.search, color: coffeeDark),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coffeeBrown,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        searchQuery = _searchController.text.toLowerCase();
                        searchTriggered = true;
                      });
                    },
                    child: const Text("Search"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Customer list
              Expanded(
                child: StreamBuilder<List<Customer>>(
                  stream: CustomerService.streamCustomers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allCustomers = snapshot.data!;
                    final filtered =
                        allCustomers.where((c) {
                          final query = searchQuery.trim();
                          return c.name.toLowerCase().contains(query) ||
                              c.invoiceNo.toLowerCase().contains(query) ||
                              c.contact.toLowerCase().contains(query);
                        }).toList();

                    if (searchTriggered && filtered.isEmpty) {
                      return const Center(child: Text("Customer not found."));
                    }

                    if (!searchTriggered) {
                      return const Center(
                        child: Text("Enter Customer details for Search."),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final customer = filtered[index];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: coffeeAccent.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetail(
                                  Icons.person,
                                  "Customer",
                                  customer.name,
                                  iconColor: coffeeDark,
                                ),
                                _buildDetail(
                                  Icons.receipt_long,
                                  "Invoice No",
                                  customer.invoiceNo,
                                  iconColor: coffeeDark,
                                ),
                                _buildDetail(
                                  Icons.phone,
                                  "Contact",
                                  customer.contact,
                                  iconColor: coffeeDark,
                                ),
                                _buildDetail(
                                  Icons.home,
                                  "Address",
                                  customer.address,
                                  iconColor: coffeeDark,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: coffeeBrown,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CustomerFormScreen(
                                                  customer: customer,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final userId =
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid;
                                        await CustomerService.deleteCustomer(
                                          userId,
                                          customer.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: coffeeBrown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Customer",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
        },
      ),
    );
  }
}
