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

import '../widgets/app_menu_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      resizeToAvoidBottomInset: false,
      endDrawer: const AppMenuDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.bgApp,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
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
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              tooltip: 'Menu Tiện Ích',
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
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

              // Tab Content Body (Dynamically Adapts Height To Selected Tab)
              Builder(
                builder: (context) {
                  switch (_selectedIndex) {
                    case 0:
                      return const HistoryTab();
                    case 1:
                      return const ChartTab();
                    case 2:
                      return const BadgesTab();
                    case 3:
                      return const WishlistTab();
                    default:
                      return const HistoryTab();
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill(String title, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
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
