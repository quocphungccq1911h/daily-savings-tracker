import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/app_menu_drawer.dart';
import '../widgets/collapsible_form.dart';
import '../widgets/overview_banner_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final bgColor = isDark ? AppTheme.bgApp : AppTheme.bgAppLight;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      endDrawer: const AppMenuDrawer(),
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                  Text(
                    'Sổ Tiết Kiệm Daily',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    'Mục tiêu: ${Formatters.formatShortNumber(state.dailyGoal)}/ngày',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
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
              icon: Icon(Icons.menu_rounded, color: titleColor, size: 26),
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
              const CollapsibleFormWidget(),

              // Custom Glassmorphic TabBar (Evenly Fitted Across Screen Width)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(child: _buildTabPill('📋 Nhật ký', 0, isDark)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildTabPill('📈 Biểu đồ', 1, isDark)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildTabPill('🏆 Huy hiệu', 2, isDark)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildTabPill('🎯 Wishlist', 3, isDark)),
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

  Widget _buildTabPill(String title, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final unselectedBg = isDark ? AppTheme.bgCard : Colors.white;
    final unselectedBorder = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final unselectedTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
    final selectedTextColor = isDark ? Colors.white : AppTheme.skyBlueAccent;

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
          color: isSelected ? AppTheme.skyBlueAccent.withValues(alpha: 0.2) : unselectedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.skyBlueAccent : unselectedBorder,
          ),
          boxShadow: (!isSelected && !isDark)
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? selectedTextColor : unselectedTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
