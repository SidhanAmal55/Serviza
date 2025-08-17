import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePreviewPage extends StatefulWidget {
  final String? invoiceNo;
  final String? invoiceDate;
  final String? dueDate;
  final String? customerName;
  final String? customerAddress;
  final List<Map<String, dynamic>>? itemList;
  final double? advance;
  final double? discount;

  const InvoicePreviewPage({
    super.key,
    this.invoiceNo,
    this.invoiceDate,
    this.dueDate,
    this.customerName,
    this.customerAddress,
    this.itemList,
    this.advance,
    this.discount,
  });

  @override
  State<InvoicePreviewPage> createState() => _InvoicePreviewPageState();
}

class _InvoicePreviewPageState extends State<InvoicePreviewPage> {
  final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  double total = 0.0;
  double grandtotal = 0.0;

  final GlobalKey _invoiceKey = GlobalKey();

  final List<Map<String, dynamic>> items = [
    {'item': '', 'qty': '', 'rate': '', 'amount': 0},
  ];

  String? customerName;
  String? customerAddress;
  String invoiceDate = "01/08/2025";
  double subtotal = 0.0;
  String? status;

  @override
  void dispose() {
    invoiceNoController.dispose();
    _invoiceDateController.dispose();
    for (var row in itemControllers) {
      for (var controller in row.values) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  List<Map<String, TextEditingController>> itemControllers = [];

  @override
  void initState() {
    super.initState();

    invoiceNoController.text = widget.invoiceNo ?? '';
    _invoiceDateController.text = widget.invoiceDate ?? '';
    _discountController.text = widget.discount?.toString() ?? '0';
    _advanceController.text = widget.advance?.toString() ?? '0';

    customerName = widget.customerName ?? '';
    customerAddress = widget.customerAddress ?? '';

    if (widget.itemList != null && widget.itemList!.isNotEmpty) {
      items.clear();
      items.addAll(widget.itemList!);
    }
    _initControllers();
    _calculateTotal();
  }

  void _initControllers() {
    itemControllers = List.generate(items.length, (index) {
      return {
        'item': TextEditingController(
          text: items[index]['item']?.toString() ?? '',
        ),
        'qty': TextEditingController(
          text: items[index]['qty']?.toString() ?? '',
        ),
        'rate': TextEditingController(
          text: items[index]['rate']?.toString() ?? '',
        ),
      };
    });
  }

  void addItem() {
    setState(() {
      items.add({'item': '', 'qty': '', 'rate': ''});
      itemControllers.add({
        'item': TextEditingController(),
        'qty': TextEditingController(),
        'rate': TextEditingController(),
      });
    });
  }

  void _deleteItem(int index) {
    setState(() {
      items.removeAt(index);
      itemControllers.removeAt(index);
      _calculateTotal();
    });
  }

  Future<void> saveInvoiceToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (invoiceNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invoice Number is required.')));
      return;
    }

    final invoiceId = invoiceNoController.text.trim();

    try {
      final invoiceRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(invoiceId);

      final snapshot = await invoiceRef.get();

      final invoiceData = {
        'invoiceNo': invoiceId,
        'invoiceDate': _invoiceDateController.text.trim(),
        'customerName': customerName ?? '',
        'customerAddress': customerAddress ?? '',
        'subtotal': subtotal,
        'advance': double.tryParse(_advanceController.text) ?? 0.0,
        'balanceAmount': total,
        'items': items,
        'timestamp': FieldValue.serverTimestamp(),
        'status': status ?? "Pending..",
        'discount': double.tryParse(_discountController.text) ?? 0.0,
      };

      if (snapshot.exists) {
        // Update existing invoice
        await invoiceRef.set(invoiceData);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invoice updated successfully')));
      } else {
        // Create new invoice
        await invoiceRef.set(invoiceData);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invoice created successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save invoice: $e')));
    }
  }

  Future<void> fetchCustomerDetails(String invoiceNo) async {
    final invoiceDate = _invoiceDateController.text.trim();

    if (invoiceNo.isEmpty || invoiceDate.isEmpty) {
      setState(() {
        customerName = 'Enter invoice no and date';
        customerAddress = '';
      });
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          customerName = 'User not logged in';
          customerAddress = '';
        });
        return;
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid) // 🟢 dynamic UID
              .collection('customers')
              .where('invoiceNo', isEqualTo: invoiceNo)
              .where('date', isEqualTo: invoiceDate)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          customerName = data['name'] ?? 'N/A';
          customerAddress = data['address'] ?? 'N/A';
        });
      } else {
        setState(() {
          customerName = 'Not Found';
          customerAddress = '';
        });
      }
    } catch (e) {
      setState(() {
        customerName = 'Error';
        customerAddress = '';
      });
    }
  }

  // double calculateTotal() {
  //   return items.fold(0, (sum, item) {
  //     final qty = double.tryParse(item['qty']) ?? 0;
  //     final rate = double.tryParse(item['rate']) ?? 0;
  //     return sum + qty * rate;
  //   });
  // }

  void _calculateTotal() {
    double tempSubtotal = 0.0;
    for (var item in items) {
      double quantity = double.tryParse(item['qty'] ?? '') ?? 0.0;
      double rate = double.tryParse(item['rate'] ?? '') ?? 0.0;
      tempSubtotal += quantity * rate;
    }

    double disc = double.tryParse(_discountController.text) ?? 0.0;
    double adv = double.tryParse(_advanceController.text) ?? 0.0;

    setState(() {
      subtotal = tempSubtotal;
      grandtotal = subtotal - disc;
      total = grandtotal - adv;
    });
  }

  // void _deleteItem(int index) {
  //   setState(() {
  //     if (items.length > 1) {
  //       items.removeAt(index);
  //       _calculateTotal();
  //     }
  //   });
  // }

  // void addItem() {
  //   setState(() {
  //     items.add({'item': '', 'qty': '', 'rate': '', 'amount': 0});
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // final total = calculateTotal();
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeLight = Color(0xFFF5E6D3);
    const Color coffeeTan = Color(0xFFD7B899);
    const Color coffeeAccent = Color(0xFF8D6E63);

    return Scaffold(
      backgroundColor: coffeeLight,
      appBar: AppBar(
        title: const Text(
          'Invoice Preview',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: coffeeDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 3,
                  shadowColor: const Color(0xFF8D6E63).withOpacity(0.3),
                  color: const Color(
                    0xFFF5E6D3,
                  ), // light coffee beige background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cash Invoice",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8D6E63), // coffee accent
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "Bismi Cater Events",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF5D4037), // dark coffee
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: invoiceNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice No',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: fetchCustomerDetails,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _invoiceDateController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        _invoiceDateController
                                            .text = DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(picked);
                                        fetchCustomerDetails(
                                          invoiceNoController.text,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "Bill To:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037), // dark coffee
                          ),
                        ),
                        Text(
                          customerName ?? "Customer Name",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF3E2723), // deep coffee
                          ),
                        ),
                        Text(
                          customerAddress ?? "Customer Address",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF3E2723),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildItemTable(),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(
                                0xFF8D6E63,
                              ), // coffee accent
                            ),
                            onPressed: addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(color: Color(0xFF5D4037)),
                                  ),
                                  Text(
                                    "₹${subtotal.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Discount",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _discountController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                      ),
                                      onChanged: (_) => _calculateTotal(),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    " Grand Total:",
                                    style: TextStyle(
                                      color: Color(0xFF5D4037),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "₹${grandtotal.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Color(0xFF5D4037),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Advance",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _advanceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                      ),
                                      onChanged: (_) => _calculateTotal(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    " Net Balance ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                  Text(
                                    "₹ ${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTable() {
    final headers = ['Item', 'Qty', 'Rate', 'Amount', ''];
    return Table(
      border: TableBorder.all(
        color: const Color(0xFF8D6E63), // coffee accent border
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFFD7CCC8), // light coffee header background
          ),
          children:
              headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723), // deep coffee text
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;

          return TableRow(
            children: [
              _buildItemCell(index, 'item'),
              _buildItemCell(index, 'qty'),
              _buildItemCell(index, 'rate'),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  ((num.tryParse(item['qty'].toString()) ?? 0) *
                          (num.tryParse(item['rate'].toString()) ?? 0))
                      .toStringAsFixed(2),
                  style: const TextStyle(
                    color: Color(0xFF5D4037), // primary coffee text
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Color(0xFFB71C1C), // strong red for delete
                ),
                onPressed: () => _deleteItem(index),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildItemCell(int index, String field) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      child: TextField(
        controller: itemControllers[index][field],
        decoration: InputDecoration(
          isDense: true,
          hintText:
              field == 'item' ? 'Item' : (field == 'qty' ? 'Qty' : 'Rate'),
          hintStyle: const TextStyle(color: Color(0xFF8D6E63)),
          filled: true,
          fillColor: Color(0xFFFFF8F1),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF8D6E63)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5D4037), width: 1.8),
          ),
        ),
        style: const TextStyle(
          color: Color(0xFF3E2723),
          fontWeight: FontWeight.w500,
        ),
        onChanged: (value) {
          items[index][field] = value;
          _calculateTotal();
        },
        keyboardType:
            field == 'item' ? TextInputType.text : TextInputType.number,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final actions = [
      // _buildActionButton(Icons.edit, 'Edit', () {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text("You can directly edit on screen")),
      //   );
      // }),
      _buildActionButton(Icons.save, 'Save', () {
        saveInvoiceToFirebase();
      }),
      _buildActionButton(Icons.send, 'Send', () {
        _sendInvoice(context);
      }),
      _buildActionButton(Icons.share, 'Share', () {
        _shareInvoice(context);
      }),
      _buildActionButton(Icons.picture_as_pdf, 'PDF/Print', () async {
        final pdf = await generateInvoicePdf(); // already defined in your code
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      }),

      _buildActionButton(Icons.payment, 'Payment', () {
        _markAsPaid(context);
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              actions
                  .map(
                    (widget) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: widget,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  void _sendInvoice(BuildContext context) {
    final buffer = StringBuffer();

    buffer.writeln("🧾 *Invoice Details*");
    buffer.writeln("");
    buffer.writeln("Invoice No: ${invoiceNoController.text}");
    buffer.writeln("Invoice Date: ${_invoiceDateController.text}");
    buffer.writeln("");
    buffer.writeln("👤 *Customer*");
    buffer.writeln("Name: ${customerName ?? ''}");
    buffer.writeln("Address: ${customerAddress ?? ''}");
    buffer.writeln("");
    buffer.writeln("📦 *Items*");

    for (var item in items) {
      final name = item['item'] ?? '';
      final qty = item['qty'] ?? '';
      final rate = item['rate'] ?? '';
      final amount = ((num.tryParse(item['qty'].toString()) ?? 0) *
              (num.tryParse(item['rate'].toString()) ?? 0))
          .toStringAsFixed(2);
      buffer.writeln("- $name | Qty: $qty | Rate: $rate | Amt: ₹$amount");
    }

    buffer.writeln("");
    buffer.writeln("Subtotal: ₹${subtotal.toStringAsFixed(2)}");
    buffer.writeln("Advance: ₹${_discountController.text}");
    buffer.writeln("Balance Amount: ₹${total.toStringAsFixed(2)}");

    Share.share(buffer.toString());
  }

  // pw.Widget _pdfLabelValue(String label, String? value) {
  //   return pw.Padding(
  //     padding: const pw.EdgeInsets.only(bottom: 4),
  //     child: pw.Row(
  //       children: [
  //         pw.Text(
  //           "$label ",
  //           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //         ),
  //         pw.Text(value ?? ''),
  //       ],
  //     ),
  //   );
  // }

  Future<pw.Document> generateInvoicePdf() async {
    // Load assets
    final logoImage = pw.MemoryImage(
      (await rootBundle.load(
        'assets/images/Bismi Logo.png',
      )).buffer.asUint8List(),
    );

    final topLeftImage = pw.MemoryImage(
      (await rootBundle.load(
        'assets/images/top_left wave.png',
      )).buffer.asUint8List(),
    );

    final bottomRightImage = pw.MemoryImage(
      (await rootBundle.load(
        'assets/images/bottom_right.png',
      )).buffer.asUint8List(),
    );

    final pdf = pw.Document();

    // ------- Prepare parsed items and totals -------
    final parsedItems =
        items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final qty = double.tryParse(item['qty']?.toString() ?? '') ?? 0.0;
          final rate = double.tryParse(item['rate']?.toString() ?? '') ?? 0.0;
          final amount = qty * rate;
          return {
            'index': idx + 1,
            'item': (item['item'] ?? '').toString(),
            'qty': qty,
            'rate': rate,
            'amount': amount,
          };
        }).toList();

    final double subtotal = parsedItems.fold(
      0.0,
      (acc, e) => acc + (e['amount'] as double),
    );
    final double discountVal = double.tryParse(_discountController.text) ?? 0.0;
    final double advanceVal = double.tryParse(_advanceController.text) ?? 0.0;
    final double grandTotal = subtotal - discountVal;
    final double total = grandTotal - advanceVal; // Net Balance

    // ------- Local helper widgets (keeps cells consistent) -------
    pw.Widget _pdfCell(
      String text, {
      pw.Alignment align = pw.Alignment.centerLeft,
      bool bold = false,
    }) {
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    pw.Widget _pdfPriceRow(String label, String value, {bool isBold = false}) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      );
    }

    // ------- Build PDF -------
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),

          // Watermark (all pages) + first-page top-left art
          buildBackground:
              (context) => pw.FullPage(
                ignoreMargins: true, // ✅ ignores page content margin
                child: pw.Stack(
                  children: [
                    // Watermark (all pages)
                    pw.Positioned.fill(
                      child: pw.Center(
                        child: pw.Opacity(
                          opacity: 0.06,
                          child: pw.Image(logoImage, width: 280),
                        ),
                      ),
                    ),

                    // First page only top-left art
                    if (context.pageNumber == 1)
                      pw.Positioned(
                        top: 0,
                        left: 0,
                        child: pw.Image(topLeftImage, width: 180),
                      ),
                  ],
                ),
              ),
          buildForeground:
              (context) => pw.FullPage(
                ignoreMargins: true, // ✅ ignore margins here too
                child: pw.Stack(
                  children: [
                    if (context.pageNumber == context.pagesCount)
                      pw.Positioned(
                        bottom: 0,
                        right: 0,
                        child: pw.Image(bottomRightImage, width: 180),
                      ),
                  ],
                ),
              ),
        ),
        // Keep header/footer null for a clean look (you can change if needed)
        header: null,
        footer: null,

        build:
            (context) => [
              // Company heading
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(height: 120),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Bismi Cater Events',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Iringavoor, Cheriyamundam, Tirur'),
                      pw.Text('Phone: 9048984583, 9847297669'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Bill To and Invoice details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Bill To",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(customerName ?? ''),
                      pw.Text(customerAddress ?? ''),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Invoice Details",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("Invoice No.: ${invoiceNoController.text}"),
                      pw.Text("Date: ${_invoiceDateController.text}"),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ---------------- Items table (manual) ----------------
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.7),
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(1.0),
                  3: pw.FlexColumnWidth(1.0),
                  4: pw.FlexColumnWidth(1.2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.yellow),
                    children: [
                      _pdfCell(
                        '#',
                        align: pw.Alignment.centerRight,
                        bold: true,
                      ),
                      _pdfCell(
                        'Item Name',
                        align: pw.Alignment.centerLeft,
                        bold: true,
                      ),
                      _pdfCell(
                        'Quantity',
                        align: pw.Alignment.centerRight,
                        bold: true,
                      ),
                      _pdfCell(
                        'Rate',
                        align: pw.Alignment.centerRight,
                        bold: true,
                      ),
                      _pdfCell(
                        'Amount',
                        align: pw.Alignment.centerRight,
                        bold: true,
                      ),
                    ],
                  ),

                  // Body rows (zebra)
                  ...parsedItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final it = entry.value;
                    final bg =
                        idx.isEven ? PdfColors.yellow200 : PdfColors.yellow300;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        _pdfCell(
                          '${it['index']}',
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(
                          '${it['item']}',
                          align: pw.Alignment.centerLeft,
                        ),
                        _pdfCell(
                          (it['qty'] as double).toStringAsFixed(0),
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(
                          (it['rate'] as double).toStringAsFixed(2),
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(
                          (it['amount'] as double).toStringAsFixed(2),
                          align: pw.Alignment.centerRight,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals box (right aligned)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 240,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.yellow200,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfPriceRow("Total", "${subtotal.toStringAsFixed(2)}/-"),
                      _pdfPriceRow(
                        "Discount",
                        "${discountVal.toStringAsFixed(2)}/-",
                      ),
                      _pdfPriceRow(
                        "Grand Total",
                        "${grandTotal.toStringAsFixed(2)}/-",
                      ),
                      _pdfPriceRow(
                        "Advance",
                        "${advanceVal.toStringAsFixed(2)}/-",
                      ),
                      pw.Divider(thickness: 0.8, color: PdfColors.grey600),
                      _pdfPriceRow(
                        "Net Balance",
                        "${total.toStringAsFixed(2)}/-",
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // Amount in words
              pw.Container(
                color: PdfColors.yellow,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                child: pw.Text(
                  "Amount in Words",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(_convertToWords(total)), // assumes you have this helper

              pw.SizedBox(height: 16),

              // Terms
              pw.Container(
                color: PdfColors.yellow,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                child: pw.Text(
                  "Terms and Conditions",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text("Thank you for doing business with us."),
            ],
      ),
    );

    return pdf;
  }

  // pw.Widget _pdfPriceRow(String label, String value, {bool isBold = false}) {
  //   return pw.Padding(
  //     padding: const pw.EdgeInsets.symmetric(vertical: 2),
  //     child: pw.Row(
  //       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //       children: [
  //         pw.Text(
  //           label,
  //           style: pw.TextStyle(
  //             fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
  //           ),
  //         ),
  //         pw.Text(
  //           value,
  //           style: pw.TextStyle(
  //             fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _convertToWords(double number) {
    final int n = number.round();

    if (n == 0) return "Zero Rupees only";

    final List<String> units = [
      "",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
    ];
    final List<String> teens = [
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen",
    ];
    final List<String> tens = [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety",
    ];
    final List<String> thousands = ["", "Thousand", "Lakh", "Crore"];

    String convertChunk(int number) {
      if (number == 0) return "";
      if (number < 10) return units[number];
      if (number < 20) return teens[number - 10];
      if (number < 100) {
        return tens[number ~/ 10] +
            (number % 10 != 0 ? " ${units[number % 10]}" : "");
      }
      if (number < 1000) {
        return units[number ~/ 100] +
            " Hundred" +
            (number % 100 != 0 ? " and ${convertChunk(number % 100)}" : "");
      }
      return "";
    }

    String result = "";
    int crore = (n ~/ 10000000);
    int lakh = (n ~/ 100000) % 100;
    int thousand = (n ~/ 1000) % 100;
    int hundred = (n % 1000);

    if (crore > 0) result += "${convertChunk(crore)} Crore ";
    if (lakh > 0) result += "${convertChunk(lakh)} Lakh ";
    if (thousand > 0) result += "${convertChunk(thousand)} Thousand ";
    if (hundred > 0) result += "${convertChunk(hundred)}";

    return result.trim() + " Rupees only";
  }

  Future<void> _shareInvoice(BuildContext context) async {
    final pdfFile = await generateInvoicePdf(); // Your PDF generation function
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/invoice_${invoiceNoController.text}.pdf';

    final file = File(filePath);
    await file.writeAsBytes(await pdfFile.save());

    Share.shareXFiles([
      XFile(filePath),
    ], text: 'Invoice PDF: ${invoiceNoController.text}');
  }

  void _markAsPaid(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Payment Status"),
            content: Text("Mark this invoice as paid?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  status = "Paid";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invoice marked as paid.")),
                  );
                },
                child: Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancel"),
              ),
            ],
          ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: Color(0xFF5D4037),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
