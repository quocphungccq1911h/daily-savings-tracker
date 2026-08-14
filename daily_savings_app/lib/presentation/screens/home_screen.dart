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

import '../widgets/auth_dialog.dart';
import '../../services/supabase_service.dart';

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
    final user = SupabaseService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppTheme.bgApp,
        elevation: 0,
        title: Row(
          children: [
            const Text('💰', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sổ Tiết Kiệm Daily',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Mục tiêu: ${Formatters.formatShortNumber(state.dailyGoal)}/ngày',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () async {
                await SupabaseService.signOut();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.emeraldLight.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '👤 ${user?.email ?? 'User'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.logout, size: 14, color: AppTheme.emeraldLight),
                  ],
                ),
              ),
            ),
          ),
        ],
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

            // Custom Glassmorphic TabBar (Evenly Fitted Across Screen Width)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildTabPill('📋 Nhật ký', 0)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTabPill('📈 Biểu đồ', 1)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTabPill('🏆 Huy hiệu', 2)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTabPill('🎯 Wishlist', 3)),
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
    return InkWell(
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: Alignment.center,
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
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
