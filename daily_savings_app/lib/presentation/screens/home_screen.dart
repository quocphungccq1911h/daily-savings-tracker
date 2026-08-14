import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';
import '../widgets/overview_banner_card.dart';
import '../widgets/collapsible_form.dart';
import '../widgets/toast_notification.dart';
import 'tabs/badges_tab.dart';
import 'tabs/chart_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/wishlist_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bgApp,
        elevation: 0,
        title: Row(
          children: [
            const Text('💰', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sổ Tiết Kiệm Daily',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Mục tiêu: ${Formatters.formatShortNumber(state.dailyGoal)}/ngày',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Hero Overview Banner Card
            const OverviewBannerCard(),

            // Collapsible Form Widget
            CollapsibleFormWidget(
              onSaved: () {
                ToastNotification.show(context, 'Đã lưu khoản tiết kiệm!');
              },
            ),

            // Custom Glassmorphic TabBar (Horizontal Touch-Swipe)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabPill('📋 Nhật ký', 0),
                  _buildTabPill('📈 Biểu đồ', 1),
                  _buildTabPill('🏆 Huy hiệu 2/8', 2),
                  _buildTabPill('🎯 Wishlist 3', 3),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Flexible PageView Tabs
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                children: const [
                  HistoryTab(),
                  ChartTab(),
                  BadgesTab(),
                  WishlistTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String title, int index) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.skyBlueAccent.withOpacity(0.2)
                : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppTheme.skyBlueAccent
                  : AppTheme.borderColor,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
