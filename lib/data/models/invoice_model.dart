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
    };
  }
}
