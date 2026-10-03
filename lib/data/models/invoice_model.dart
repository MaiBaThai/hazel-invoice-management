import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  final String serviceName;
  final double price;

  ServiceItem({required this.serviceName, required this.price});

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      serviceName: map['service_name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_name': serviceName,
      'price': price,
    };
  }
}

class Invoice {
  final String id;
  final String customerId;
  final String customerName;
  final List<ServiceItem> services;
  final double subtotal;
  final double discountPercent;
  final double finalTotal;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime? sessionStart;
  final DateTime? sessionEnd;
  final double tip;
  final double commissionPercent;
  final List<String> staffNames;
  final String notes;

  Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.services,
    required this.subtotal,
    required this.discountPercent,
    required this.finalTotal,
    required this.photoUrls,
    required this.createdAt,
    this.sessionStart,
    this.sessionEnd,
    this.tip = 0.0,
    this.commissionPercent = 0.0,
    this.staffNames = const [],
    this.notes = '',
  });

  factory Invoice.fromMap(String id, Map<String, dynamic> map) {
    return Invoice(
      id: id,
      customerId: map['customer_id'] ?? '',
      customerName: map['customer_name'] ?? '',
      services: (map['services'] as List? ?? [])
          .map((s) => ServiceItem.fromMap(s as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      discountPercent: (map['discount_percent'] ?? 0.0).toDouble(),
      finalTotal: (map['final_total'] ?? 0.0).toDouble(),
      photoUrls: List<String>.from(map['photoUrls'] ?? map['photo_urls'] ?? []),
      createdAt: (map['created_at'] as Timestamp).toDate(),
      sessionStart: map['session_start'] != null ? (map['session_start'] as Timestamp).toDate() : null,
      sessionEnd: map['session_end'] != null ? (map['session_end'] as Timestamp).toDate() : null,
      tip: (map['tip'] ?? 0.0).toDouble(),
      commissionPercent: (map['commission_percent'] ?? 0.0).toDouble(),
      staffNames: List<String>.from(map['staff_names'] ?? (map['staff_name'] != null ? [map['staff_name']] : [])),
      notes: map['notes'] ?? map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'services': services.map((s) => s.toMap()).toList(),
      'subtotal': subtotal,
      'discount_percent': discountPercent,
      'final_total': finalTotal,
      'photoUrls': photoUrls,
      'created_at': Timestamp.fromDate(createdAt),
      'session_start': sessionStart != null ? Timestamp.fromDate(sessionStart!) : null,
      'session_end': sessionEnd != null ? Timestamp.fromDate(sessionEnd!) : null,
      'tip': tip,
      'commission_percent': commissionPercent,
      'staff_names': staffNames,
      'notes': notes,
    };
  }

  Invoice copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<ServiceItem>? services,
    double? subtotal,
    double? discountPercent,
    double? finalTotal,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? sessionStart,
    DateTime? sessionEnd,
    double? tip,
    double? commissionPercent,
    List<String>? staffNames,
    String? notes,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      services: services ?? this.services,
      subtotal: subtotal ?? this.subtotal,
      discountPercent: discountPercent ?? this.discountPercent,
      finalTotal: finalTotal ?? this.finalTotal,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
      tip: tip ?? this.tip,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      staffNames: staffNames ?? this.staffNames,
      notes: notes ?? this.notes,
    );
  }
}
