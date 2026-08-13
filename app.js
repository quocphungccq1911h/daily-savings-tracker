// Sổ Tiết Kiệm Daily - Core Application Logic
(function () {
  const STORAGE_KEY = 'savings_tracker_entries_v1';
  const GOAL_STORAGE_KEY = 'savings_tracker_daily_goal_v1';

  // Default Daily Goal
  let dailyGoal = parseInt(localStorage.getItem(GOAL_STORAGE_KEY)) || 150000;
  let entries = JSON.parse(localStorage.getItem(STORAGE_KEY)) || [];

  // Chart instance reference
  let savingsChartInstance = null;

  // DOM Elements
  const headerGoalDisplay = document.getElementById('headerGoalDisplay');
  const currentDateBadge = document.getElementById('currentDateBadge');
  const statusPaceAmount = document.getElementById('statusPaceAmount');
  const statusPacePill = document.getElementById('statusPacePill');
  const cumulativeTargetDisplay = document.getElementById('cumulativeTargetDisplay');

  const monthSavedTotal = document.getElementById('monthSavedTotal');
  const monthTargetTotal = document.getElementById('monthTargetTotal');
  const monthProgressBar = document.getElementById('monthProgressBar');
  const monthPercentText = document.getElementById('monthPercentText');
  const monthRemainingNeed = document.getElementById('monthRemainingNeed');
  const monthDailyAdvice = document.getElementById('monthDailyAdvice');
  const currentMonthName = document.getElementById('currentMonthName');

  const yearSavedTotal = document.getElementById('yearSavedTotal');
  const yearForecastTotal = document.getElementById('yearForecastTotal');
  const yearProgressBar = document.getElementById('yearProgressBar');
  const yearPercentText = document.getElementById('yearPercentText');
  const avgDailyRateText = document.getElementById('avgDailyRateText');
  const currentYearName = document.getElementById('currentYearName');

  // Form DOM
  const savingsForm = document.getElementById('savingsForm');
  const entryId = document.getElementById('entryId');
  const entryDate = document.getElementById('entryDate');
  const entryAmount = document.getElementById('entryAmount');
  const entryNote = document.getElementById('entryNote');
  const saveBtn = document.getElementById('saveBtn');
  const cancelEditBtn = document.getElementById('cancelEditBtn');
  const entryPreviewBox = document.getElementById('entryPreviewBox');
  const prevTarget = document.getElementById('prevTarget');
  const prevStatusTag = document.getElementById('prevStatusTag');
  const prevDetailText = document.getElementById('prevDetailText');

  // Tables & Filters
  const savingsTableBody = document.getElementById('savingsTableBody');
  const filterMonthSelect = document.getElementById('filterMonthSelect');
  const chartMonthSelect = document.getElementById('chartMonthSelect');
  const clearAllBtn = document.getElementById('clearAllBtn');

  // Modal DOM
  const configGoalBtn = document.getElementById('configGoalBtn');
  const goalModal = document.getElementById('goalModal');
  const modalGoalInput = document.getElementById('modalGoalInput');
  const saveGoalModalBtn = document.getElementById('saveGoalModalBtn');
  const closeGoalModalBtn = document.getElementById('closeGoalModalBtn');

  // Backup DOM
  const exportDataBtn = document.getElementById('exportDataBtn');
  const importDataBtn = document.getElementById('importDataBtn');
  const importFileInput = document.getElementById('importFileInput');

  // Currency Formatter
  function formatVND(amount) {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount).replace('₫', 'đ');
  }

  // Format short number for display
  function formatShortNumber(num) {
    return new Intl.NumberFormat('vi-VN').format(Math.round(num)) + ' đ';
  }

  // Initialize Sample Data if empty
  function seedInitialSampleData() {
    if (entries.length === 0) {
      const today = new Date();
      const currentYear = today.getFullYear();
      const currentMonthStr = String(today.getMonth() + 1).padStart(2, '0');
      
      // Sample data: 1/8 140k as user requested, and recent days
      entries = [
        { id: 'sample-1', date: `${currentYear}-${currentMonthStr}-01`, amount: 140000, note: 'Khởi đầu tháng (nhẹ hơn target 10k)' },
        { id: 'sample-2', date: `${currentYear}-${currentMonthStr}-02`, amount: 160000, note: 'Dư 10k bù cho ngày 1' },
        { id: 'sample-3', date: `${currentYear}-${currentMonthStr}-03`, amount: 150000, note: 'Đúng kế hoạch 150k' },
        { id: 'sample-4', date: `${currentYear}-${currentMonthStr}-04`, amount: 150000, note: 'Đúng kế hoạch 150k' },
        { id: 'sample-5', date: `${currentYear}-${currentMonthStr}-05`, amount: 200000, note: 'Thưởng công việc +50k' },
      ];
      saveToStorage();
    }
  }

  function saveToStorage() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
    localStorage.setItem(GOAL_STORAGE_KEY, dailyGoal.toString());
  }

  // Set Default Date to Today
  function setDefaultDate() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    entryDate.value = `${yyyy}-${mm}-${dd}`;
  }

  // Initialize Month Options in Select Dropdowns
  function populateMonthSelects() {
    const monthsSet = new Set();
    const today = new Date();
    const currentMonthKey = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}`;
    monthsSet.add(currentMonthKey);

    entries.forEach(item => {
      if (item.date) {
        const monthKey = item.date.substring(0, 7);
        monthsSet.add(monthKey);
      }
    });

    const sortedMonths = Array.from(monthsSet).sort().reverse();

    filterMonthSelect.innerHTML = '';
    chartMonthSelect.innerHTML = '';

    sortedMonths.forEach(mKey => {
      const [year, month] = mKey.split('-');
      const optionText = `Tháng ${parseInt(month)}/${year}`;

      const opt1 = document.createElement('option');
      opt1.value = mKey;
      opt1.textContent = optionText;

      const opt2 = document.createElement('option');
      opt2.value = mKey;
      opt2.textContent = optionText;

      filterMonthSelect.appendChild(opt1);
      chartMonthSelect.appendChild(opt2);
    });

    filterMonthSelect.value = currentMonthKey;
    chartMonthSelect.value = currentMonthKey;
  }

  // Realtime Form Entry Preview
  function updateEntryPreview() {
    const val = parseFloat(entryAmount.value) || 0;
    prevTarget.textContent = formatShortNumber(dailyGoal);

    const diff = val - dailyGoal;
    const percent = ((diff / dailyGoal) * 100).toFixed(1);

    if (diff === 0) {
      prevStatusTag.className = 'status-tag tag-equal';
      prevStatusTag.textContent = 'Đạt mục tiêu';
      prevDetailText.textContent = 'Đúng kế hoạch kỳ vọng! (0%)';
    } else if (diff > 0) {
      prevStatusTag.className = 'status-tag tag-success';
      prevStatusTag.textContent = 'Vượt mục tiêu';
      prevDetailText.textContent = `Thừa +${formatShortNumber(diff)} (+${percent}% so với kỳ vọng)`;
    } else {
      prevStatusTag.className = 'status-tag tag-danger';
      prevStatusTag.textContent = 'Thiếu mục tiêu';
      prevDetailText.textContent = `Thiếu ${formatShortNumber(Math.abs(diff))} (${percent}% so với kỳ vọng)`;
    }
  }

  // Render Dashboard Cards & Metrics
  function renderDashboard() {
    headerGoalDisplay.textContent = formatShortNumber(dailyGoal);
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1; // 1-12
    const currentDay = now.getDate(); // 1-31

    currentDateBadge.textContent = `${String(currentDay).padStart(2, '0')}/${String(currentMonth).padStart(2, '0')}/${currentYear}`;
    currentMonthName.textContent = `Tháng ${currentMonth}/${currentYear}`;
    currentYearName.textContent = `Năm ${currentYear}`;

    // 1. Current Month Entries
    const currentMonthPrefix = `${currentYear}-${String(currentMonth).padStart(2, '0')}`;
    const monthEntries = entries.filter(e => e.date && e.date.startsWith(currentMonthPrefix));

    // Cumulative Target & Saved up to Today
    const totalDaysInMonth = new Date(currentYear, currentMonth, 0).getDate();
    const cumulativeTargetToToday = currentDay * dailyGoal;
    cumulativeTargetDisplay.textContent = formatShortNumber(cumulativeTargetToToday);

    // Sum saved up to current day
    let monthTotalSaved = 0;
    let savedUpToToday = 0;

    monthEntries.forEach(e => {
      const dayNum = parseInt(e.date.split('-')[2]);
      monthTotalSaved += e.amount;
      if (dayNum <= currentDay) {
        savedUpToToday += e.amount;
      }
    });

    // Card 1 Pace Calculation (Difference up to today)
    const paceDiff = savedUpToToday - cumulativeTargetToToday;
    if (paceDiff >= 0) {
      statusPaceAmount.textContent = `+${formatShortNumber(paceDiff)}`;
      statusPaceAmount.className = 'main-stat text-success';
      statusPacePill.className = 'stat-status-pill pill-success';
      statusPacePill.textContent = paceDiff === 0 ? 'Vừa đủ kế hoạch' : `Dư ${formatShortNumber(paceDiff)} so với tiến độ`;
    } else {
      const diffAbs = Math.abs(paceDiff);
      statusPaceAmount.textContent = `-${formatShortNumber(diffAbs)}`;
      statusPaceAmount.className = 'main-stat text-danger';
      statusPacePill.className = 'stat-status-pill pill-danger';
      statusPacePill.textContent = `Đang thiếu ${formatShortNumber(diffAbs)} so với tiến độ`;
    }

    // Card 2: Current Month Progress
    const monthTarget = totalDaysInMonth * dailyGoal;
    monthSavedTotal.textContent = formatShortNumber(monthTotalSaved);
    monthTargetTotal.textContent = formatShortNumber(monthTarget);

    const monthPct = Math.min(100, Math.round((monthTotalSaved / monthTarget) * 100));
    monthProgressBar.style.width = `${monthPct}%`;
    monthPercentText.textContent = `${monthPct}% mục tiêu tháng`;

    const remainingNeed = monthTarget - monthTotalSaved;
    if (remainingNeed <= 0) {
      monthRemainingNeed.textContent = 'Đã hoàn thành 100%! 🎉';
      monthDailyAdvice.innerHTML = 'Chúc mừng! Bạn đã hoàn thành xuất sắc mục tiêu tháng!';
    } else {
      monthRemainingNeed.textContent = `Còn cần: ${formatShortNumber(remainingNeed)}`;
      const remainingDays = totalDaysInMonth - currentDay;
      if (remainingDays > 0) {
        const requiredDailyAvg = Math.ceil(remainingNeed / remainingDays);
        monthDailyAdvice.innerHTML = `Gợi ý: Cần trung bình <strong>${formatShortNumber(requiredDailyAvg)}/ngày</strong> cho ${remainingDays} ngày còn lại trong tháng.`;
      } else {
        monthDailyAdvice.innerHTML = `Đã hết tháng. Còn thiếu <strong>${formatShortNumber(remainingNeed)}</strong> để đạt kế hoạch.`;
      }
    }

    // Card 3: Annual Forecast & Progress
    const yearEntries = entries.filter(e => e.date && e.date.startsWith(`${currentYear}`));
    let yearTotalSaved = 0;
    yearEntries.forEach(e => yearTotalSaved += e.amount);

    const totalDaysInYear = (currentYear % 4 === 0 && currentYear % 100 !== 0) || (currentYear % 400 === 0) ? 366 : 365;
    const yearTarget = totalDaysInYear * dailyGoal;

    // Calculate elapsed days in year up to today
    const startOfYear = new Date(currentYear, 0, 1);
    const elapsedDays = Math.max(1, Math.floor((now - startOfYear) / (1000 * 60 * 60 * 24)) + 1);

    const realAvgRate = yearTotalSaved / Math.max(1, yearEntries.length || elapsedDays);
    const yearForecast = Math.round(realAvgRate * totalDaysInYear);

    yearSavedTotal.textContent = formatShortNumber(yearTotalSaved);
    yearForecastTotal.textContent = formatShortNumber(yearForecast);

    const yearPct = Math.min(100, ((yearTotalSaved / yearTarget) * 100).toFixed(1));
    yearProgressBar.style.width = `${yearPct}%`;
    yearPercentText.textContent = `${yearPct}% mục tiêu cả năm (${formatShortNumber(yearTarget)})`;
    avgDailyRateText.textContent = `${formatShortNumber(realAvgRate)}/ngày`;
  }

  // Render Table
  function renderTable() {
    const selectedMonth = filterMonthSelect.value;
    savingsTableBody.innerHTML = '';

    const filtered = entries.filter(e => e.date && e.date.startsWith(selectedMonth));
    filtered.sort((a, b) => b.date.localeCompare(a.date));

    if (filtered.length === 0) {
      savingsTableBody.innerHTML = `
        <tr>
          <td colspan="7" class="text-center" style="padding: 24px; color: var(--text-muted);">
            Chưa có dữ liệu tiết kiệm nào cho ${selectedMonth.replace('-', '/')}. Hãy nhập số tiền bên trái!
          </td>
        </tr>
      `;
      return;
    }

    filtered.forEach(item => {
      const tr = document.createElement('tr');
      const diff = item.amount - dailyGoal;
      const percent = ((diff / dailyGoal) * 100).toFixed(1);

      let diffCell = '';
      let statusCell = '';
      let pctCell = '';

      if (diff === 0) {
        diffCell = `<span class="text-info">0 đ</span>`;
        statusCell = `<span class="status-tag tag-equal">Đạt 100%</span>`;
        pctCell = `<span class="text-info">0%</span>`;
      } else if (diff > 0) {
        diffCell = `<span class="text-success">+${formatShortNumber(diff)}</span>`;
        statusCell = `<span class="status-tag tag-success">Thừa target</span>`;
        pctCell = `<span class="text-success">+${percent}%</span>`;
      } else {
        diffCell = `<span class="text-danger">-${formatShortNumber(Math.abs(diff))}</span>`;
        statusCell = `<span class="status-tag tag-danger">Thiếu target</span>`;
        pctCell = `<span class="text-danger">${percent}%</span>`;
      }

      // Format Date
      const dateParts = item.date.split('-');
      const formattedDate = `${dateParts[2]}/${dateParts[1]}/${dateParts[0]}`;

      tr.innerHTML = `
        <td><strong>${formattedDate}</strong></td>
        <td class="text-success"><strong>${formatShortNumber(item.amount)}</strong></td>
        <td>${diffCell}</td>
        <td>${pctCell}</td>
        <td>${statusCell}</td>
        <td><span style="color: var(--text-muted); font-size: 0.85rem;">${item.note || '-'}</span></td>
        <td class="text-center">
          <button class="action-btn edit-btn" data-id="${item.id}" title="Chỉnh sửa">✏️</button>
          <button class="action-btn delete-btn" data-id="${item.id}" title="Xóa">🗑️</button>
        </td>
      `;

      savingsTableBody.appendChild(tr);
    });

    // Attach Event Listeners to Action Buttons
    document.querySelectorAll('.edit-btn').forEach(btn => {
      btn.addEventListener('click', (e) => editEntry(e.currentTarget.dataset.id));
    });

    document.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', (e) => deleteEntry(e.currentTarget.dataset.id));
    });
  }

  // Render Chart
  function renderChart() {
    const selectedMonth = chartMonthSelect.value;
    if (!selectedMonth) return;

    const [year, month] = selectedMonth.split('-').map(Number);
    const daysInMonth = new Date(year, month, 0).getDate();

    const labels = [];
    const actualData = [];
    const targetData = [];

    // Map entries by day
    const dayMap = {};
    entries.forEach(e => {
      if (e.date && e.date.startsWith(selectedMonth)) {
        const day = parseInt(e.date.split('-')[2]);
        dayMap[day] = e.amount;
      }
    });

    for (let d = 1; d <= daysInMonth; d++) {
      labels.push(`${d}/${month}`);
      actualData.push(dayMap[d] || 0);
      targetData.push(dailyGoal);
    }

    const ctx = document.getElementById('savingsChart').getContext('2d');

    if (savingsChartInstance) {
      savingsChartInstance.destroy();
    }

    savingsChartInstance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Tiết kiệm thực tế (VNĐ)',
            data: actualData,
            backgroundColor: actualData.map(v => v >= dailyGoal ? 'rgba(16, 185, 129, 0.75)' : (v > 0 ? 'rgba(239, 68, 68, 0.75)' : 'rgba(148, 163, 184, 0.2)')),
            borderColor: actualData.map(v => v >= dailyGoal ? '#10b981' : (v > 0 ? '#ef4444' : '#475569')),
            borderWidth: 1.5,
            borderRadius: 4
          },
          {
            label: `Mục tiêu (${formatShortNumber(dailyGoal)}/ngày)`,
            data: targetData,
            type: 'line',
            borderColor: '#f59e0b',
            borderWidth: 2,
            borderDash: [5, 5],
            pointRadius: 0,
            fill: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: {
              color: '#94a3b8',
              callback: function (value) { return (value / 1000) + 'k'; }
            }
          },
          x: {
            grid: { display: false },
            ticks: { color: '#94a3b8', font: { size: 10 } }
          }
        },
        plugins: {
          legend: { labels: { color: '#cbd5e1' } },
          tooltip: {
            callbacks: {
              label: function (context) {
                return `${context.dataset.label}: ${formatShortNumber(context.raw)}`;
              }
            }
          }
        }
      }
    });
  }

  // Handle Form Submission
  savingsForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const dateVal = entryDate.value;
    const amountVal = parseFloat(entryAmount.value);
    const noteVal = entryNote.value.trim();
    const existingId = entryId.value;

    if (!dateVal || isNaN(amountVal) || amountVal < 0) {
      alert('Vui lòng nhập ngày và số tiền hợp lệ!');
      return;
    }

    if (existingId) {
      // Edit existing
      const idx = entries.findIndex(item => item.id === existingId);
      if (idx !== -1) {
        entries[idx] = { id: existingId, date: dateVal, amount: amountVal, note: noteVal };
      }
    } else {
      // Check if entry for date already exists
      const existingDateIdx = entries.findIndex(item => item.date === dateVal);
      if (existingDateIdx !== -1) {
        if (confirm(`Ngày ${dateVal} đã có ghi nhận ${formatShortNumber(entries[existingDateIdx].amount)}. Bạn có muốn ghi đè số tiền mới là ${formatShortNumber(amountVal)} không?`)) {
          entries[existingDateIdx].amount = amountVal;
          entries[existingDateIdx].note = noteVal;
        } else {
          return;
        }
      } else {
        // Add new
        entries.push({
          id: 'entry-' + Date.now(),
          date: dateVal,
          amount: amountVal,
          note: noteVal
        });
      }
    }

    saveToStorage();
    resetForm();
    refreshAll();
  });

  function resetForm() {
    entryId.value = '';
    entryAmount.value = '150000';
    entryNote.value = '';
    saveBtn.textContent = '💾 Lưu Tiết Kiệm Ngày Này';
    saveBtn.className = 'btn btn-primary btn-block';
    cancelEditBtn.style.display = 'none';
    setDefaultDate();
    updateEntryPreview();
  }

  function editEntry(id) {
    const item = entries.find(e => e.id === id);
    if (!item) return;

    entryId.value = item.id;
    entryDate.value = item.date;
    entryAmount.value = item.amount;
    entryNote.value = item.note || '';

    saveBtn.textContent = '🔄 Cập Nhật Số Tiền';
    saveBtn.className = 'btn btn-primary btn-block';
    cancelEditBtn.style.display = 'block';

    updateEntryPreview();
    entryAmount.focus();
  }

  function deleteEntry(id) {
    const item = entries.find(e => e.id === id);
    if (!item) return;

    if (confirm(`Bạn có chắc chắn muốn xóa ghi nhận ngày ${item.date} (${formatShortNumber(item.amount)})?`)) {
      entries = entries.filter(e => e.id !== id);
      saveToStorage();
      refreshAll();
    }
  }

  cancelEditBtn.addEventListener('click', resetForm);

  // Quick Preset Buttons (+50k, +100k, +150k, +200k)
  document.querySelectorAll('.preset-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('active'));
      e.currentTarget.classList.add('active');
      entryAmount.value = e.currentTarget.dataset.val;
      updateEntryPreview();
    });
  });

  entryAmount.addEventListener('input', updateEntryPreview);

  // Goal Modal Handlers
  configGoalBtn.addEventListener('click', () => {
    modalGoalInput.value = dailyGoal;
    goalModal.style.display = 'flex';
  });

  closeGoalModalBtn.addEventListener('click', () => {
    goalModal.style.display = 'none';
  });

  saveGoalModalBtn.addEventListener('click', () => {
    const newGoal = parseInt(modalGoalInput.value);
    if (isNaN(newGoal) || newGoal <= 0) {
      alert('Vui lòng nhập mục tiêu hợp lệ (> 0 VNĐ)!');
      return;
    }
    dailyGoal = newGoal;
    saveToStorage();
    goalModal.style.display = 'none';
    updateEntryPreview();
    refreshAll();
  });

  // Export JSON Backup
  exportDataBtn.addEventListener('click', () => {
    const backupData = {
      version: 1,
      dailyGoal: dailyGoal,
      exportedAt: new Date().toISOString(),
      entries: entries
    };

    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(backupData, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", `SaoLuu_TietKiem_${new Date().toISOString().substring(0, 10)}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  });

  // Import JSON Backup
  importDataBtn.addEventListener('click', () => importFileInput.click());

  importFileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = function (event) {
      try {
        const imported = JSON.parse(event.target.result);
        if (imported.entries && Array.isArray(imported.entries)) {
          if (confirm(`Tìm thấy ${imported.entries.length} ghi nhận. Bạn có muốn ghi đè lên dữ liệu hiện tại không?`)) {
            entries = imported.entries;
            if (imported.dailyGoal) dailyGoal = imported.dailyGoal;
            saveToStorage();
            refreshAll();
            alert('Khôi phục dữ liệu thành công!');
          }
        } else {
          alert('File không hợp lệ!');
        }
      } catch (err) {
        alert('Lỗi đọc file: ' + err.message);
      }
    };
    reader.readAsText(file);
  });

  // Clear All Data
  clearAllBtn.addEventListener('click', () => {
    if (confirm('CẢNH BÁO: Bạn có chắc chắn muốn xóa TOÀN BỘ nhật ký tiết kiệm không? Hành động này không thể hoàn tác!')) {
      entries = [];
      saveToStorage();
      refreshAll();
    }
  });

  filterMonthSelect.addEventListener('change', renderTable);
  chartMonthSelect.addEventListener('change', renderChart);

  function refreshAll() {
    populateMonthSelects();
    renderDashboard();
    renderTable();
    renderChart();
  }

  // App Initialize
  seedInitialSampleData();
  setDefaultDate();
  entryAmount.value = dailyGoal;
  updateEntryPreview();
  refreshAll();

})();
