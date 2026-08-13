# 💰 Daily Savings Tracker (Sổ Tiết Kiệm Daily)

Ứng dụng Web App quản lý, theo dõi và báo cáo tiến độ tiết kiệm hàng ngày đơn giản, trực quan và bảo mật 100%.

![Daily Savings Tracker Banner](https://img.shields.io/badge/Status-Active-emerald?style=for-the-badge)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)

---

## ✨ Tính Năng Nổi Bật

- 🎯 **Quản lý mục tiêu linh hoạt:** Mặc định **150.000 VNĐ/ngày** (có thể điều chỉnh tùy chọn).
- 📊 **Phân tích từng ngày:**
  - Tự động so sánh số tiền đã lưu so với mục tiêu.
  - Hiển thị số tiền thiếu/thừa và tỷ lệ % chênh lệch so với kỳ vọng (VD: Thiếu 10k = -6.67%).
- 📈 **Báo cáo Lũy kế Tiến độ:**
  - Cho biết chính xác tính đến ngày hiện tại trong tháng bạn đang **dư hay thiếu** bao nhiêu tiền so với kế hoạch.
  - Gợi ý mức tiết kiệm trung bình cần đạt cho các ngày còn lại trong tháng.
- 🔮 **Dự báo cả năm (Forecast):** Dựa trên tốc độ tiết kiệm thực tế để dự báo số tiền tích lũy được sau 1 năm (mục tiêu 365 ngày = 54.750.000 VNĐ).
- 📉 **Biểu đồ trực quan:** Tích hợp Chart.js so sánh mức tiết kiệm thực tế vs đường mốc 150k.
- 🔒 **Bảo mật & Riêng tư (LocalStorage):** Không cần CSDL/Server, dữ liệu lưu an toàn 100% trên trình duyệt của bạn.
- 📥 **Export / Import Backup:** Xuất/Nhập file sao lưu JSON dễ dàng chỉ bằng 1 click.

---

## 🛠️ Công Nghệ Sử Dụng

- **Frontend:** HTML5, Vanilla CSS3 (Dark Glassmorphism UI), JavaScript (ES6+).
- **Lưu trữ:** Web Storage API (`localStorage`).
- **Biểu đồ:** [Chart.js](https://www.chartjs.org/).

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

Không cần cài đặt Node.js hay Server! Bạn chỉ cần:
1. Clone repo này về máy:
   ```bash
   git clone https://github.com/YOUR_USERNAME/daily-savings-tracker.git
   ```
2. Mở file `index.html` trực tiếp bằng bất kỳ trình duyệt nào (Chrome, Edge, Firefox, Brave,...).
