import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/customer_model.dart';
import 'package:myapp/services/customer_service.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _invoiceController = TextEditingController();
  final _dateController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _invoiceFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _invoiceFocus.dispose();
    _contactFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      final c = widget.customer!;
      _invoiceController.text = c.invoiceNo;
      _dateController.text = c.date;
      _nameController.text = c.name;
      _addressController.text = c.address;
      _contactController.text = c.contact;
    } else {
      _dateController.text = DateTime.now().toIso8601String().split('T').first;
    }
  }

  void saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to save a customer.'),
          ),
        );
        return;
      }

      final newCustomer = Customer(
        id: widget.customer?.id ?? '',
        invoiceNo: _invoiceController.text.trim(),
        date: _dateController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        contact: _contactController.text.trim(),
      );

      if (widget.customer == null) {
        await CustomerService.addCustomer(user.uid, newCustomer);
      } else {
        await CustomerService.updateCustomer(
          user.uid,
          widget.customer!.id,
          newCustomer,
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeLight = Color(0xFFF5E6D3);
    const Color coffeeTan = Color(0xFFD7B899);
    const Color coffeeAccent = Color(0xFF8D6E63);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer == null ? 'Add Customer' : 'Edit Customer',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: coffeeDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Customer Details",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: coffeeDark,
                ),
              ),
              _buildTextField(
                controller: _invoiceController,
                label: "Invoice Number",
                currentFocus: _invoiceFocus,
                nextFocus: _nameFocus,
              ),
              _buildTextField(
                controller: _dateController,
                label: 'Date (YYYY-MM-DD)',
                nextFocus: _nameFocus,
              ),
              _buildTextField(
                controller: _nameController,
                label: "Name",
                currentFocus: _nameFocus,
                nextFocus: _contactFocus,
              ),
              _buildTextField(
                controller: _contactController,
                label: "Contact",
                currentFocus: _contactFocus,
                nextFocus: _addressFocus,
              ),
              _buildTextField(
                controller: _addressController,
                label: "Address",
                currentFocus: _addressFocus,
                nextFocus: _emailFocus,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coffeeDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  onPressed: saveCustomer,
                  child: const Text(
                    'Save Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    FocusNode? currentFocus,
    FocusNode? nextFocus,
  }) {
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeLight = Color(0xFFF5E6D3);
    const Color coffeeTan = Color(0xFFD7B899);
    const Color coffeeAccent = Color(0xFF8D6E63);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        focusNode: currentFocus,
        textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: coffeeDark),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: coffeeLight, // Light background from coffee theme
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: coffeeTan), // Coffee tan border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: coffeeAccent,
              width: 2,
            ), // Accent focus
          ),
        ),
        validator:
            (value) =>
                (value == null || value.isEmpty) ? 'Please enter $label' : null,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(currentFocus!.context!).requestFocus(nextFocus);
          } else {
            currentFocus?.unfocus();
          }
        },
      ),
    );
  }
}
