import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeBlock {
  final int hour;
  final int minute;
  TimeBlock(this.hour, this.minute);

  String get label {
    if (hour == 0 && minute == 0) return '24:00';
    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  int get minutesSinceStartOfDay {
    if (hour == 0 && minute == 0) return 24 * 60;
    return hour * 60 + minute;
  }

  DateTime toDateTime(DateTime date) {
    if (hour == 0 && minute == 0) {
      // Midnight / 24:00 is technically 00:00 of the next day
      final nextDay = date.add(const Duration(days: 1));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 0, 0);
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

class SessionTimePickerDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final Function(DateTime start, DateTime end) onSave;

  const SessionTimePickerDialog({
    super.key,
    this.initialStart,
    this.initialEnd,
    required this.onSave,
  });

  @override
  State<SessionTimePickerDialog> createState() => _SessionTimePickerDialogState();
}

class _SessionTimePickerDialogState extends State<SessionTimePickerDialog> {
  late DateTime _selectedDate;
  TimeBlock? _startBlock;
  TimeBlock? _endBlock;
  late final List<TimeBlock> _timeBlocks;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialStart ?? DateTime.now();
    _timeBlocks = _generateTimeBlocks();
    _initFromWidget();
  }

  List<TimeBlock> _generateTimeBlocks() {
    final List<TimeBlock> blocks = [];
    for (int h = 7; h <= 23; h++) {
      blocks.add(TimeBlock(h, 0));
      blocks.add(TimeBlock(h, 30));
    }
    blocks.add(TimeBlock(0, 0)); // 24:00 / midnight
    return blocks;
  }

  void _initFromWidget() {
    if (widget.initialStart != null) {
      final start = widget.initialStart!;
      _startBlock = _timeBlocks.firstWhere(
        (b) => b.hour == start.hour && b.minute == start.minute,
        orElse: () => TimeBlock(start.hour, start.minute),
      );
    }
    if (widget.initialEnd != null) {
      final end = widget.initialEnd!;
      // Check if end is next day 00:00, which corresponds to 24:00
      final isMidnight = end.hour == 0 && end.minute == 0 && end.day != _selectedDate.day;
      if (isMidnight) {
        _endBlock = _timeBlocks.firstWhere(
          (b) => b.hour == 0 && b.minute == 0,
          orElse: () => TimeBlock(0, 0),
        );
      } else {
        _endBlock = _timeBlocks.firstWhere(
          (b) => b.hour == end.hour && b.minute == end.minute,
          orElse: () => TimeBlock(end.hour, end.minute),
        );
      }
    }
  }

  void _handleBlockTap(TimeBlock block) {
    setState(() {
      if (_startBlock == null) {
        _startBlock = block;
      } else if (_endBlock == null) {
        if (block.minutesSinceStartOfDay > _startBlock!.minutesSinceStartOfDay) {
          _endBlock = block;
        } else if (block.minutesSinceStartOfDay < _startBlock!.minutesSinceStartOfDay) {
          _startBlock = block;
        }
        // Tapping the same block twice is not allowed, so do nothing.
      } else {
        // Both are already selected, start over
        _startBlock = block;
        _endBlock = null;
      }
    });
  }

  bool _isBlockSelected(TimeBlock block) {
    if (_startBlock != null && _startBlock!.minutesSinceStartOfDay == block.minutesSinceStartOfDay) {
      return true;
    }
    if (_endBlock != null && _endBlock!.minutesSinceStartOfDay == block.minutesSinceStartOfDay) {
      return true;
    }
    return false;
  }

  bool _isBlockInRange(TimeBlock block) {
    if (_startBlock == null || _endBlock == null) return false;
    final startVal = _startBlock!.minutesSinceStartOfDay;
    final endVal = _endBlock!.minutesSinceStartOfDay;
    final blockVal = block.minutesSinceStartOfDay;
    return blockVal > startVal && blockVal < endVal;
  }

  String _getDurationText() {
    if (_startBlock == null || _endBlock == null) return '';
    final diffMinutes = _endBlock!.minutesSinceStartOfDay - _startBlock!.minutesSinceStartOfDay;
    final hours = diffMinutes / 60.0;
    final formattedHours = hours.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '$formattedHours hr${hours == 1 ? '' : 's'}';
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    
    final dayStr = DateFormat('EEEE, dd/MM/yyyy').format(date);
    if (diff == 0) {
      return 'Today ($dayStr)';
    } else if (diff == -1) {
      return 'Yesterday ($dayStr)';
    } else if (diff == 1) {
      return 'Tomorrow ($dayStr)';
    }
    return dayStr;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final hasSelection = _startBlock != null && _endBlock != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Session Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Picker Title
                    const Text(
                      'SESSION DATE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.pink),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                              });
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  _getFormattedDate(_selectedDate),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.pink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.pink),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.add(const Duration(days: 1));
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time Blocks Title
                    const Text(
                      'SELECT START & END TIME',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap first block for Start, and second block for End time.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Grid of Blocks
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1.9,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _timeBlocks.length,
                      itemBuilder: (context, index) {
                        final block = _timeBlocks[index];
                        final isSelected = _isBlockSelected(block);
                        final isInRange = _isBlockInRange(block);

                        Color? bgColor;
                        Color? textColor;
                        Border? border;

                        if (isSelected) {
                          bgColor = Colors.pink;
                          textColor = Colors.white;
                          border = Border.all(color: Colors.pink);
                        } else if (isInRange) {
                          bgColor = Colors.pink.withOpacity(0.1);
                          textColor = Colors.pink;
                          border = Border.all(color: Colors.pink.withOpacity(0.2));
                        } else {
                          bgColor = Colors.white;
                          textColor = Colors.black87;
                          border = Border.all(color: Colors.grey[200]!);
                        }

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleBlockTap(block),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(6),
                                border: border,
                              ),
                              child: Text(
                                block.label,
                                style: TextStyle(
                                  fontWeight: isSelected || isInRange ? FontWeight.bold : FontWeight.normal,
                                  color: textColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status summary
                  if (hasSelection)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${dateFormat.format(_selectedDate)} | ${_startBlock!.label} - ${_endBlock!.label} (${_getDurationText()})',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else if (_startBlock != null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_right_alt, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Tap end block to complete duration...',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_outlined, color: Colors.grey, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Please select session duration',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: hasSelection
                              ? () {
                                  final startDt = _startBlock!.toDateTime(_selectedDate);
                                  final endDt = _endBlock!.toDateTime(_selectedDate);
                                  widget.onSave(startDt, endDt);
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.pink.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('SAVE DURATION', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
