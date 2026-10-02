import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../data/services/database_service.dart';

enum CsvDateRange {
  allTime,
  last30Days,
  last90Days,
  ytd,
  custom,
}

class CsvExportDialog extends StatefulWidget {
  final DatabaseService dbService;

  const CsvExportDialog({
    super.key,
    required this.dbService,
  });

  static Future<void> show(BuildContext context, DatabaseService dbService) {
    return showDialog(
      context: context,
      builder: (context) => CsvExportDialog(dbService: dbService),
    );
  }

  @override
  State<CsvExportDialog> createState() => _CsvExportDialogState();
}

class _CsvExportDialogState extends State<CsvExportDialog> {
  bool _exportInvoices = true;
  bool _exportCustomers = true;
  bool _exportExpenses = true;
  bool _exportBookings = true;

  CsvDateRange _selectedRange = CsvDateRange.allTime;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  bool _isExporting = false;

  (DateTime?, DateTime?) _calculateDateRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case CsvDateRange.allTime:
        return (null, null);
      case CsvDateRange.last30Days:
        final start = now.subtract(const Duration(days: 30));
        return (start, now);
      case CsvDateRange.last90Days:
        final start = now.subtract(const Duration(days: 90));
        return (start, now);
      case CsvDateRange.ytd:
        final start = DateTime(now.year, 1, 1);
        return (start, now);
      case CsvDateRange.custom:
        return (_customStartDate, _customEndDate);
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _customStartDate ?? now.subtract(const Duration(days: 7)),
      end: _customEndDate ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _selectedRange = CsvDateRange.custom;
      });
    }
  }

  Future<void> _onExportPressed() async {
    if (!_exportInvoices && !_exportCustomers && !_exportExpenses && !_exportBookings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final (startDate, endDate) = _calculateDateRange();

    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = CsvExportService(widget.dbService);
      await exportService.exportSelectedData(
        exportInvoices: _exportInvoices,
        exportCustomers: _exportCustomers,
        exportExpenses: _exportExpenses,
        exportBookings: _exportBookings,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.table_chart_rounded, color: Colors.pink),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Export Data (CSV)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Categories',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Invoices', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Sales, discounts, and revenue', style: TextStyle(fontSize: 11)),
              value: _exportInvoices,
              activeColor: Colors.pink,
              onChanged: _isExporting ? null : (v) => setState(() => _exportInvoices = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Contacts, spending history, and last visit', style: TextStyle(fontSize: 11)),
              value: _exportCustomers,
              activeColor: Colors.pink,
              onChanged: _isExporting ? null : (v) => setState(() => _exportCustomers = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Operating costs and supply notes', style: TextStyle(fontSize: 11)),
              value: _exportExpenses,
              activeColor: Colors.pink,
              onChanged: _isExporting ? null : (v) => setState(() => _exportExpenses = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Bookings', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Appointments and calendar notes', style: TextStyle(fontSize: 11)),
              value: _exportBookings,
              activeColor: Colors.pink,
              onChanged: _isExporting ? null : (v) => setState(() => _exportBookings = v ?? false),
            ),
            const Divider(height: 24),
            const Text(
              'Date Range',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CsvDateRange>(
              value: _selectedRange,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: CsvDateRange.allTime, child: Text('All Time')),
                DropdownMenuItem(value: CsvDateRange.last30Days, child: Text('Last 30 Days')),
                DropdownMenuItem(value: CsvDateRange.last90Days, child: Text('Last 90 Days')),
                DropdownMenuItem(value: CsvDateRange.ytd, child: Text('Year to Date (YTD)')),
                DropdownMenuItem(value: CsvDateRange.custom, child: Text('Custom Date Range...')),
              ],
              onChanged: _isExporting
                  ? null
                  : (value) {
                      if (value != null) {
                        if (value == CsvDateRange.custom) {
                          _pickDateRange();
                        } else {
                          setState(() {
                            _selectedRange = value;
                          });
                        }
                      }
                    },
            ),
            if (_selectedRange == CsvDateRange.custom) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _isExporting ? null : _pickDateRange,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.pink.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.pink.withOpacity(0.04),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _customStartDate != null && _customEndDate != null
                            ? '${dateFormat.format(_customStartDate!)} - ${dateFormat.format(_customEndDate!)}'
                            : 'Select Date Range',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.pink),
                      ),
                      const Icon(Icons.calendar_today, size: 16, color: Colors.pink),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _onExportPressed,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download_rounded, size: 18),
          label: Text(_isExporting ? 'Preparing...' : 'Export CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
