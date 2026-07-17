import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String notes;
  final String? googleEventId;
  final String? appleEventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.notes,
    this.googleEventId,
    this.appleEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      title: map['title'] ?? '',
      startTime: map['start_time'] != null
          ? (map['start_time'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: map['end_time'] != null
          ? (map['end_time'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 1)),
      notes: map['notes'] ?? '',
      googleEventId: map['google_event_id'],
      appleEventId: map['apple_event_id'],
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'title': title,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'notes': notes,
      'google_event_id': googleEventId,
      'apple_event_id': appleEventId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? googleEventId,
    String? appleEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      googleEventId: googleEventId ?? this.googleEventId,
      appleEventId: appleEventId ?? this.appleEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
