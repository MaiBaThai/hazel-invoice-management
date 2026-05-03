import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseItem {
  final String description;
  final double cost;

  ExpenseItem({required this.description, required this.cost});

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      description: map['description'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'cost': cost,
    };
  }
}

class Expense {
  final String id;
  final List<ExpenseItem> items;
  final double totalCost;
  final String note;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.items,
    required this.totalCost,
    required this.note,
    required this.createdAt,
  });

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      items: (map['items'] as List? ?? [])
          .map((i) => ExpenseItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      totalCost: (map['total_cost'] ?? 0.0).toDouble(),
      note: map['note'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((i) => i.toMap()).toList(),
      'total_cost': totalCost,
      'note': note,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
