import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../ocr/presentation/camera_scanner_sheet.dart';
import 'expense_list_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ExpenseListScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      // AppBar matching Slide 33-34
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.receipt_long, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('VKU Expense OCR'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Chuyển đổi giao diện Sáng/Tối',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),

      // Body (Primary Content)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // FloatingActionButton matching Slide 34
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CameraScannerSheet.show(context, ref),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Quét hóa đơn'),
      ),

      // NavigationBar matching Slide 34
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Báo cáo',
          ),
        ],
      ),
    );
  }
}
