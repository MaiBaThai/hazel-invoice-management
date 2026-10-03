import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String id;
  final String name;
  final String phone;
  final double defaultCommissionPercent;
  final DateTime createdAt;
  final bool isActive;

  Staff({
    required this.id,
    required this.name,
    required this.phone,
    this.defaultCommissionPercent = 0.0,
    required this.createdAt,
    this.isActive = true,
  });

  factory Staff.fromMap(String id, Map<String, dynamic> map) {
    return Staff(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      defaultCommissionPercent:
          (map['default_commission_percent'] ?? 0.0).toDouble(),
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'name_lowercase': name.toLowerCase(),
      'phone': phone,
      'default_commission_percent': defaultCommissionPercent,
      'created_at': Timestamp.fromDate(createdAt),
      'is_active': isActive,
    };
  }

  Staff copyWith({
    String? id,
    String? name,
    String? phone,
    double? defaultCommissionPercent,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      defaultCommissionPercent:
          defaultCommissionPercent ?? this.defaultCommissionPercent,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
