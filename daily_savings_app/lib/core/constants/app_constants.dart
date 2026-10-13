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

  // Default Wishlist Goals (6 mục tiêu phân tầng từ ngắn hạn -> dài hạn)
  static const List<Map<String, dynamic>> defaultWishlistGoals = [
    {
      'id': 'w1_emergency',
      'title': 'Quỹ dự phòng khẩn cấp (3 tháng)',
      'target_amount': 15000000.0,
      'targetAmount': 15000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🛡️',
    },
    {
      'id': 'w2_gold',
      'title': 'Mua 3 chỉ Vàng nhẫn tích trữ',
      'target_amount': 30000000.0,
      'targetAmount': 30000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🪙',
    },
    {
      'id': 'w3_motorbike',
      'title': 'Quỹ nâng cấp / Đổi xe chạy Grab',
      'target_amount': 50000000.0,
      'targetAmount': 50000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🛵',
    },
    {
      'id': 'w4_passbook',
      'title': 'Sổ tiết kiệm / Đầu tư 100 Triệu',
      'target_amount': 100000000.0,
      'targetAmount': 100000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '📜',
    },
    {
      'id': 'w5_land',
      'title': 'Mua đất tích sản',
      'target_amount': 200000000.0,
      'targetAmount': 200000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🏞️',
    },
    {
      'id': 'w6_house',
      'title': 'Xây nhà / Mua nhà an cư',
      'target_amount': 500000000.0,
      'targetAmount': 500000000.0,
      'allocated_amount': 0.0,
      'allocatedAmount': 0.0,
      'emoji': '🏠',
    },
  ];

  // Milestone Badges (20 Levels: 5tr each, from 5tr up to 100tr)
  static const List<Map<String, dynamic>> milestoneBadges = [
    {'id': 'b1',  'name': 'Khởi Đầu',          'amount': 5000000.0,   'icon': '🌱'},
    {'id': 'b2',  'name': 'Vững Bước',         'amount': 10000000.0,  'icon': '🥉'},
    {'id': 'b3',  'name': 'Kiên Trì',          'amount': 15000000.0,  'icon': '🥈'},
    {'id': 'b4',  'name': 'Tích Lũy',          'amount': 20000000.0,  'icon': '🥇'},
    {'id': 'b5',  'name': 'Tăng Tốc',          'amount': 25000000.0,  'icon': '⚡'},
    {'id': 'b6',  'name': 'Bứt Phá',           'amount': 30000000.0,  'icon': '🔥'},
    {'id': 'b7',  'name': 'Vững Vàng',         'amount': 35000000.0,  'icon': '🛡️'},
    {'id': 'b8',  'name': 'Chuyên Cần',        'amount': 40000000.0,  'icon': '🐝'},
    {'id': 'b9',  'name': 'Thịnh Vượng',       'amount': 45000000.0,  'icon': '🍀'},
    {'id': 'b10', 'name': 'Nửa Đường Vàng',    'amount': 50000000.0,  'icon': '🌟'},
    {'id': 'b11', 'name': 'Bậc Thầy',          'amount': 55000000.0,  'icon': '🏅'},
    {'id': 'b12', 'name': 'Tinh Hoa',          'amount': 60000000.0,  'icon': '✨'},
    {'id': 'b13', 'name': 'Ưu Tú',             'amount': 65000000.0,  'icon': '🎖️'},
    {'id': 'b14', 'name': 'Kiệt Xuất',         'amount': 70000000.0,  'icon': '💎'},
    {'id': 'b15', 'name': 'Phú Quý',           'amount': 75000000.0,  'icon': '💰'},
    {'id': 'b16', 'name': 'Đại Gia Ngầm',      'amount': 80000000.0,  'icon': '🦁'},
    {'id': 'b17', 'name': 'Đỉnh Cao',          'amount': 85000000.0,  'icon': '🏔️'},
    {'id': 'b18', 'name': 'Siêu Phàm',         'amount': 90000000.0,  'icon': '🚀'},
    {'id': 'b19', 'name': 'Đại Phú Hộ',        'amount': 95000000.0,  'icon': '👑'},
    {'id': 'b20', 'name': 'Huyền Thoại 100Tr', 'amount': 100000000.0, 'icon': '🏛️'},
  ];
}
