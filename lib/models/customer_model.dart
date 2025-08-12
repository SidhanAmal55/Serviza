class Customer {
  late String id;
  final String invoiceNo;
  final String date;
  final String name;
  final String address;
  final String contact;

  Customer({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.name,
    required this.address,
    required this.contact,
  });

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      invoiceNo: map['invoiceNo'] ?? '',
      date: map['date'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNo': invoiceNo,
      'date': date,
      'name': name,
      'address': address,
      'contact': contact,
    };
  }
  Customer copyWith({
  String? id,
  String? invoiceNo,
  String? date,
  String? name,
  String? address,
  String? contact,
 
}) {
  return Customer(
    id: id ?? this.id,
    invoiceNo: invoiceNo ?? this.invoiceNo,
    date: date ?? this.date,
    name: name ?? this.name,
    address: address ?? this.address,
    contact: contact ?? this.contact,
   
  );
}

}
