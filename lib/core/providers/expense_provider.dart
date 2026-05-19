import 'package:flutter/material.dart';
import '../../data/models/expense_model.dart';
import '../../data/services/database_service.dart';

class ExpenseProvider with ChangeNotifier {
  DatabaseService _db;
  ExpenseProvider(this._db);

  void updateDbService(DatabaseService newService) {
    _db = newService;
    reset(); // Clear local state when user identity potentially changes
  }

  final List<ExpenseItem> _items = [];
  String _note = '';
  bool _isSaving = false;

  List<ExpenseItem> get items => List.unmodifiable(_items);
  String get note => _note;
  bool get isSaving => _isSaving;

  double get totalCost => _items.fold(0, (sum, item) => sum + item.cost);

  void addItem({String description = '', double cost = 0}) {
    _items.add(ExpenseItem(description: description, cost: cost));
    notifyListeners();
  }

  void updateItem(int index, String description, double cost) {
    if (index >= 0 && index < _items.length) {
      _items[index] = ExpenseItem(description: description, cost: cost);
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void setNote(String value) {
    _note = value;
    notifyListeners();
  }

  void reset() {
    _items.clear();
    _note = '';
    _isSaving = false;
    notifyListeners();
  }

  Future<void> saveExpense() async {
    if (_items.isEmpty) return;

    _isSaving = true;
    notifyListeners();

    try {
      final expense = Expense(
        id: '',
        items: _items,
        totalCost: totalCost,
        note: _note,
        createdAt: DateTime.now(),
      );

      await _db.saveExpense(expense);
      reset();
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      rethrow;
    }
  }
}
