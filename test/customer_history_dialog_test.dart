import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/features/dashboard/widgets/customer_history_dialog.dart';

class MockSlowDatabaseService extends DatabaseService {
  final Completer<void> completer;

  MockSlowDatabaseService(FakeFirebaseFirestore fakeDb, this.completer) 
      : super(userId: 'user_123', firestore: fakeDb);

  @override
  Future<void> deleteCustomer(String customerId) async {
    await completer.future; // Giữ hàm xóa ở trạng thái chờ
  }
}

void main() {
  testWidgets('CustomerHistoryDialog - delete customer when unmounted should not crash', (WidgetTester tester) async {
    final fakeDb = FakeFirebaseFirestore();
    final completer = Completer<void>();
    final slowDbService = MockSlowDatabaseService(fakeDb, completer);
    
    final customerProvider = CustomerProvider(slowDbService);
    final settingsProvider = SettingsProvider(slowDbService);

    // Build dialog trong một test widget
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
                          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
                        ],
                        child: const CustomerHistoryDialog(
                          customerId: 'cust_123',
                          customerName: 'Test Customer',
                          customerPhone: '123456',
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // 1. Mở CustomerHistoryDialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // 2. Mở Popup Menu và chọn "Delete Customer"
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Customer'));
    await tester.pumpAndSettle();

    // 3. Nhấp nút DELETE để kích hoạt deleteCustomer (nó sẽ bị treo ở completer.future)
    await tester.tap(find.text('DELETE'));
    await tester.pump(); // Kích hoạt sự kiện bấm nút

    // 4. Giả lập việc người dùng tắt dialog từ bên ngoài / hoặc widget cha bị unmounted
    // Bằng cách gọi Navigator.pop trên root Navigator để đóng dialog trước khi async xong
    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    navigatorState.pop(); // Đóng Confirmation Dialog
    navigatorState.pop(); // Đóng History Dialog
    await tester.pumpAndSettle();

    // Xác nhận là Dialog đã biến mất khỏi Widget tree
    expect(find.byType(CustomerHistoryDialog), findsNothing);

    // 5. Cho phép tác vụ async xóa dữ liệu hoàn tất
    completer.complete();
    
    // Đảm bảo không có lỗi ngoại lệ nào được ném ra và ứng dụng ổn định
    await tester.pumpAndSettle();
  });
}
