class AppConstants {
  // Financial Defaults
  static const double defaultDailyGoal = 150000.0; // 150.000 VNĐ / day
  
  // Income Categories
  static const List<String> incomeCategories = [
    'Grab / Chạy xe',
    'Lương cố định',
    'Thưởng',
    'Khác',
  ];

  // Expense Categories (Chi Tiêu Hằng Ngày)
  static const List<String> expenseCategories = [
    '🍲 Ăn Uống',
    '⛽ Đi Lại & Xăng Xe',
    '🛒 Đi Chợ & Siêu Thị',
    '💡 Hóa Đơn & Điện Nước',
    '☕ Cà Phê & Giải Trí',
    '🛍️ Mua Sắm Cá Nhân',
    '📦 Khác',
  ];

  static const String defaultCategory = 'Grab / Chạy xe';

  // Default Wishlist Goals (Sắp xếp tăng dần từ mục tiêu dễ đạt -> lớn hơn)
  static const List<Map<String, dynamic>> defaultWishlistGoals = [
    {
      'id': 'w3',
      'title': 'Quỹ dự phòng khẩn cấp',
      'target_amount': 10000000.0,
      'targetAmount': 10000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🛡️',
    },
    {
      'id': 'w2',
      'title': 'Mua đất',
      'target_amount': 200000000.0,
      'targetAmount': 200000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🏞️',
    },
    {
      'id': 'w1',
      'title': 'Xây nhà / Mua nhà',
      'target_amount': 500000000.0,
      'targetAmount': 500000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🏠',
    },
  ];

  // Milestone Badges (8 Levels)
  static const List<Map<String, dynamic>> milestoneBadges = [
    {'id': 'b1', 'name': 'Khởi Đầu', 'amount': 1000000.0, 'icon': '🥉'},
    {'id': 'b2', 'name': 'Tiến Bộ', 'amount': 3000000.0, 'icon': '🥈'},
    {'id': 'b3', 'name': 'Tích Lũy', 'amount': 5000000.0, 'icon': '🌟'},
    {'id': 'b4', 'name': 'Bậc Thầy', 'amount': 10000000.0, 'icon': '🥇'},
    {'id': 'b5', 'name': 'Triệu Phú', 'amount': 50000000.0, 'icon': '💎'},
    {'id': 'b6', 'name': 'Đại Phú Hộ', 'amount': 100000000.0, 'icon': '👑'},
    {'id': 'b7', 'name': 'Tỷ Phú Tương Lai', 'amount': 500000000.0, 'icon': '🚀'},
    {'id': 'b8', 'name': 'Huyền Thoại Bất Tử', 'amount': 1000000000.0, 'icon': '🏛️'},
  ];
}
