import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final double totalSpent;
  final DateTime? lastVisit;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.totalSpent = 0.0,
    this.lastVisit,
  });

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      totalSpent: (map['total_spent'] ?? 0.0).toDouble(),
      lastVisit: map['last_visit'] != null
          ? (map['last_visit'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'name_lowercase': name.toLowerCase(),
      'phone': phone,
      'total_spent': totalSpent,
      'last_visit': lastVisit != null ? Timestamp.fromDate(lastVisit!) : null,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    double? totalSpent,
    DateTime? lastVisit,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalSpent: totalSpent ?? this.totalSpent,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }
}
