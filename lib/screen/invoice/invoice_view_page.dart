import 'package:flutter/material.dart';
import 'package:myapp/screen/invoice/invoice_page.dart';

class Invoiceview extends StatelessWidget {
  final Map<String, dynamic> invoiceData;
  final List<Map<String, dynamic>> items;
  final bool isEditable;
  final String documentId;

  Invoiceview({
    Key? key,
    required this.invoiceData,
    required this.items,
    this.isEditable = false,
    required this.documentId,
  }) : super(key: key);

  final GlobalKey _previewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final Color primaryBrown = Color(0xFF6F4E37);
    final Color lightBeige = Color(0xFFF5E6D3);
    final Color creamWhite = Color(0xFFFFFBF5);

    double subtotal = items.fold(0.0, (sum, item) {
      double qty = double.tryParse('${item['qty']}') ?? 0;
      double rate = double.tryParse('${item['rate']}') ?? 0;
      return sum + (qty * rate);
    });
    double discount = double.tryParse('${invoiceData['discount'] ?? 0}') ?? 0;
    double advance = double.tryParse('${invoiceData['advance'] ?? 0}') ?? 0;
    double balance =
        double.tryParse('${invoiceData['balanceAmount'] ?? 0}') ?? 0;

    return Scaffold(
      backgroundColor: creamWhite,
      appBar: AppBar(
        backgroundColor: primaryBrown,
        iconTheme: const IconThemeData(
          color: Colors.white, // Change this to suit your background
        ),
        elevation: 0,
        title: Text(
          'Invoice',
          style: TextStyle(color: creamWhite, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isEditable)
            IconButton(
              icon: Icon(Icons.edit, color: creamWhite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => InvoicePreviewPage(
                          invoiceNo: invoiceData['invoiceNo'],
                          invoiceDate: invoiceData['invoiceDate'],
                          customerName: invoiceData['customerName'],
                          customerAddress: invoiceData['customerAddress'],
                          itemList: List<Map<String, dynamic>>.from(
                            invoiceData['items'],
                          ),
                          advance: invoiceData['advance'],
                          discount: invoiceData['discount'],
                        ),
                  ),
                );
              },
            ),
        ],
      ),
      body: RepaintBoundary(
        key: _previewKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72, // Twice the CircleAvatar radius (36 * 2)
                      height: 72,
                      decoration: BoxDecoration(
                        color: lightBeige,
                        borderRadius: BorderRadius.circular(
                          8,
                        ), // Change to 0 for perfect square
                        image: DecorationImage(
                          image: AssetImage('assets/images/Bismi Logo.png'),
                          fit:
                              BoxFit
                                  .cover, // Ensures the image covers the square
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Bismi Cater Events",
                      style: TextStyle(
                        letterSpacing: 1.5,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Bill Info Card
              _buildInfoCard(lightBeige, [
                _labelValue("BILL TO:", invoiceData['customerName']),
                Text(invoiceData['customerAddress'] ?? ''),
                SizedBox(height: 10),
                _labelValue("INVOICE NO:", invoiceData['invoiceNumber']),
                _labelValue("DATE:", invoiceData['invoiceDate']),
              ]),

              SizedBox(height: 20),

              // Items Table
              _buildInfoCard(creamWhite, [
                _tableHeader([
                  "ITEM ",
                  "UNIT PRICE",
                  "   QTY",
                  "TOTAL",
                ], primaryBrown),
                Divider(thickness: 1, color: lightBeige),
                ...items.map((item) {
                  double qty = double.tryParse('${item['qty']}') ?? 0;
                  double rate = double.tryParse('${item['rate']}') ?? 0;
                  double amt = qty * rate;
                  return _tableRow([
                    item['item'] ?? '',
                    '₹${rate.toStringAsFixed(0)}',
                    qty.toStringAsFixed(0),
                    '₹${amt.toStringAsFixed(0)}',
                  ]);
                }).toList(),
              ]),

              SizedBox(height: 20),

              // Totals Card
              _buildInfoCard(lightBeige, [
                _priceRow(
                  "Total",
                  "₹${subtotal.toStringAsFixed(0)}",
                  true,
                  primaryBrown,
                ),
                _priceRow(
                  "Discount",
                  "₹${discount.toStringAsFixed(0)}",
                  false,
                  primaryBrown,
                ),
                _priceRow(
                  "Grand Total",
                  "₹${subtotal - discount}",
                  true,
                  primaryBrown,
                ),
                _priceRow("Advance", "₹${advance}", false, primaryBrown),
                Divider(thickness: 1, color: creamWhite),
                _priceRow(
                  "Net Balance",
                  "₹${invoiceData['balanceAmount']}",
                  true,
                  Colors.redAccent,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color bgColor, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _labelValue(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: "$label ",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          children: [
            TextSpan(
              text: value ?? '',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, bool isBold, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> headers, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          headers
              .map(
                (h) => Expanded(
                  child: Text(
                    h,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _tableRow(List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            values
                .map(
                  (v) => Expanded(
                    child: Text(v, style: TextStyle(color: Colors.black87)),
                  ),
                )
                .toList(),
      ),
    );
  }
}
