// Sổ Tiết Kiệm Daily - Minimalist Version
(function () {
  const STORAGE_KEY = 'savings_tracker_entries_v1';
  const GOAL_STORAGE_KEY = 'savings_tracker_daily_goal_v1';

  let dailyGoal = parseInt(localStorage.getItem(GOAL_STORAGE_KEY)) || 150000;
  let entries = JSON.parse(localStorage.getItem(STORAGE_KEY)) || [];
  let savingsChartInstance = null;

  // DOM Elements
  const headerGoalDisplay = document.getElementById('headerGoalDisplay');
  const currentDateBadge = document.getElementById('currentDateBadge');
  const currentMonthName = document.getElementById('currentMonthName');
  const statusPaceAmount = document.getElementById('statusPaceAmount');
  const statusPacePill = document.getElementById('statusPacePill');
  const cumulativeTargetDisplay = document.getElementById('cumulativeTargetDisplay');

  const monthSavedTotal = document.getElementById('monthSavedTotal');
  const monthProgressBar = document.getElementById('monthProgressBar');
  const monthPercentText = document.getElementById('monthPercentText');
  const monthRemainingNeed = document.getElementById('monthRemainingNeed');
  const monthDailyAdvice = document.getElementById('monthDailyAdvice');

  const yearSavedTotal = document.getElementById('yearSavedTotal');
  const yearForecastTotal = document.getElementById('yearForecastTotal');
  const yearProgressBar = document.getElementById('yearProgressBar');
  const yearPercentText = document.getElementById('yearPercentText');
  const avgDailyRateText = document.getElementById('avgDailyRateText');

  // Form DOM
  const savingsForm = document.getElementById('savingsForm');
  const entryId = document.getElementById('entryId');
  const entryDate = document.getElementById('entryDate');
  const entryAmount = document.getElementById('entryAmount');
  const entryNote = document.getElementById('entryNote');
  const saveBtn = document.getElementById('saveBtn');
  const cancelEditBtn = document.getElementById('cancelEditBtn');
  const prevStatusTag = document.getElementById('prevStatusTag');
  const prevDetailText = document.getElementById('prevDetailText');

  // Table & Filters
  const savingsTableBody = document.getElementById('savingsTableBody');
  const filterMonthSelect = document.getElementById('filterMonthSelect');
  const clearAllBtn = document.getElementById('clearAllBtn');

  // Tabs
  const tabHistoryBtn = document.getElementById('tabHistoryBtn');
  const tabChartBtn = document.getElementById('tabChartBtn');
  const tabHistoryContent = document.getElementById('tabHistoryContent');
  const tabChartContent = document.getElementById('tabChartContent');

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

  function formatShortNumber(num) {
    return new Intl.NumberFormat('vi-VN').format(Math.round(num)) + ' đ';
  }

  function seedInitialSampleData() {
    if (entries.length === 0) {
      const today = new Date();
      const currentYear = today.getFullYear();
      const currentMonthStr = String(today.getMonth() + 1).padStart(2, '0');

      entries = [
        { id: 'sample-1', date: `${currentYear}-${currentMonthStr}-01`, amount: 140000, note: 'Khởi đầu tháng (nhẹ hơn target 10k)' },
        { id: 'sample-2', date: `${currentYear}-${currentMonthStr}-02`, amount: 160000, note: 'Dư 10k bù ngày 1' },
        { id: 'sample-3', date: `${currentYear}-${currentMonthStr}-03`, amount: 150000, note: 'Đúng 150k' },
        { id: 'sample-4', date: `${currentYear}-${currentMonthStr}-04`, amount: 150000, note: 'Đúng 150k' },
        { id: 'sample-5', date: `${currentYear}-${currentMonthStr}-05`, amount: 200000, note: 'Thưởng nhẹ +50k' },
      ];
      saveToStorage();
    }
  }

  function saveToStorage() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
    localStorage.setItem(GOAL_STORAGE_KEY, dailyGoal.toString());
  }

  function setDefaultDate() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    entryDate.value = `${yyyy}-${mm}-${dd}`;
  }

  function populateMonthSelect() {
    const monthsSet = new Set();
    const today = new Date();
    const currentMonthKey = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}`;
    monthsSet.add(currentMonthKey);

    entries.forEach(item => {
      if (item.date) {
        monthsSet.add(item.date.substring(0, 7));
      }
    });

    const sortedMonths = Array.from(monthsSet).sort().reverse();
    filterMonthSelect.innerHTML = '';

    sortedMonths.forEach(mKey => {
      const [year, month] = mKey.split('-');
      const opt = document.createElement('option');
      opt.value = mKey;
      opt.textContent = `Tháng ${parseInt(month)}/${year}`;
      filterMonthSelect.appendChild(opt);
    });

    filterMonthSelect.value = currentMonthKey;
  }

  function updateEntryPreview() {
    const val = parseFloat(entryAmount.value) || 0;
    const diff = val - dailyGoal;
    const percent = ((diff / dailyGoal) * 100).toFixed(1);

    if (diff === 0) {
      prevStatusTag.className = 'badge-pill pill-info';
      prevStatusTag.textContent = 'Đúng kế hoạch';
      prevDetailText.textContent = `Đạt ${formatShortNumber(dailyGoal)} (0%)`;
    } else if (diff > 0) {
      prevStatusTag.className = 'badge-pill pill-success';
      prevStatusTag.textContent = 'Vượt target';
      prevDetailText.textContent = `Thừa +${formatShortNumber(diff)} (+${percent}%)`;
    } else {
      prevStatusTag.className = 'badge-pill pill-danger';
      prevStatusTag.textContent = 'Thiếu target';
      prevDetailText.textContent = `Thiếu -${formatShortNumber(Math.abs(diff))} (${percent}%)`;
    }
  }

  function renderDashboard() {
    headerGoalDisplay.textContent = formatShortNumber(dailyGoal);

    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;
    const currentDay = now.getDate();

    currentDateBadge.textContent = `${String(currentDay).padStart(2, '0')}/${String(currentMonth).padStart(2, '0')}`;
    currentMonthName.textContent = `Tháng ${currentMonth}/${currentYear}`;

    const currentMonthPrefix = `${currentYear}-${String(currentMonth).padStart(2, '0')}`;
    const monthEntries = entries.filter(e => e.date && e.date.startsWith(currentMonthPrefix));

    const totalDaysInMonth = new Date(currentYear, currentMonth, 0).getDate();
    const cumulativeTargetToToday = currentDay * dailyGoal;
    cumulativeTargetDisplay.textContent = formatShortNumber(cumulativeTargetToToday);

    let monthTotalSaved = 0;
    let savedUpToToday = 0;

    monthEntries.forEach(e => {
      const dayNum = parseInt(e.date.split('-')[2]);
      monthTotalSaved += e.amount;
      if (dayNum <= currentDay) {
        savedUpToToday += e.amount;
      }
    });

    // Banner Status
    const paceDiff = savedUpToToday - cumulativeTargetToToday;
    if (paceDiff >= 0) {
      statusPaceAmount.textContent = paceDiff === 0 ? 'Đúng Kế Hoạch' : `+${formatShortNumber(paceDiff)}`;
      statusPaceAmount.className = 'banner-val text-success';
      statusPacePill.textContent = paceDiff === 0 ? 'Vừa đủ mục tiêu đến nay' : `Dư +${formatShortNumber(paceDiff)} so với lũy kế`;
    } else {
      const diffAbs = Math.abs(paceDiff);
      statusPaceAmount.textContent = `-${formatShortNumber(diffAbs)}`;
      statusPaceAmount.className = 'banner-val text-danger';
      statusPacePill.textContent = `Thiếu -${formatShortNumber(diffAbs)} so với lũy kế`;
    }

    // Month Progress Card
    const monthTarget = totalDaysInMonth * dailyGoal;
    monthSavedTotal.textContent = formatShortNumber(monthTotalSaved);
    const monthPct = Math.min(100, Math.round((monthTotalSaved / monthTarget) * 100));
    monthProgressBar.style.width = `${monthPct}%`;
    monthPercentText.textContent = `${monthPct}% mục tiêu`;

    const remainingNeed = monthTarget - monthTotalSaved;
    if (remainingNeed <= 0) {
      monthRemainingNeed.textContent = 'Hoàn thành 100%! 🎉';
      monthDailyAdvice.innerHTML = 'Chúc mừng! Đã đạt mục tiêu tháng!';
    } else {
      monthRemainingNeed.textContent = `Thiếu: ${formatShortNumber(remainingNeed)}`;
      const remainingDays = totalDaysInMonth - currentDay;
      if (remainingDays > 0) {
        const requiredDailyAvg = Math.ceil(remainingNeed / remainingDays);
        monthDailyAdvice.innerHTML = `Cần ~<strong>${formatShortNumber(requiredDailyAvg)}/ngày</strong> cho ${remainingDays} ngày còn lại.`;
      } else {
        monthDailyAdvice.innerHTML = `Đã hết tháng. Còn thiếu ${formatShortNumber(remainingNeed)}.`;
      }
    }

    // Annual Progress Card
    const yearEntries = entries.filter(e => e.date && e.date.startsWith(`${currentYear}`));
    let yearTotalSaved = 0;
    yearEntries.forEach(e => yearTotalSaved += e.amount);

    const totalDaysInYear = (currentYear % 4 === 0 && currentYear % 100 !== 0) || (currentYear % 400 === 0) ? 366 : 365;
    const yearTarget = totalDaysInYear * dailyGoal;

    const startOfYear = new Date(currentYear, 0, 1);
    const elapsedDays = Math.max(1, Math.floor((now - startOfYear) / (1000 * 60 * 60 * 24)) + 1);

    const realAvgRate = yearTotalSaved / Math.max(1, yearEntries.length || elapsedDays);
    const yearForecast = Math.round(realAvgRate * totalDaysInYear);

    yearSavedTotal.textContent = formatShortNumber(yearTotalSaved);
    yearForecastTotal.textContent = formatShortNumber(yearForecast);

    const yearPct = Math.min(100, ((yearTotalSaved / yearTarget) * 100).toFixed(1));
    yearProgressBar.style.width = `${yearPct}%`;
    yearPercentText.textContent = `${yearPct}% (${formatShortNumber(yearTarget)})`;
    avgDailyRateText.textContent = `${formatShortNumber(realAvgRate)}/ngày`;
  }

  function renderTable() {
    const selectedMonth = filterMonthSelect.value;
    savingsTableBody.innerHTML = '';

    const filtered = entries.filter(e => e.date && e.date.startsWith(selectedMonth));
    filtered.sort((a, b) => b.date.localeCompare(a.date));

    if (filtered.length === 0) {
      savingsTableBody.innerHTML = `
        <tr>
          <td colspan="7" class="text-center" style="padding: 18px; color: var(--text-muted);">
            Chưa có ghi nhận tiết kiệm cho ${selectedMonth.replace('-', '/')}.
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
        statusCell = `<span class="badge-pill pill-info">Đạt target</span>`;
        pctCell = `<span class="text-info">0%</span>`;
      } else if (diff > 0) {
        diffCell = `<span class="text-success">+${formatShortNumber(diff)}</span>`;
        statusCell = `<span class="badge-pill pill-success">Thừa</span>`;
        pctCell = `<span class="text-success">+${percent}%</span>`;
      } else {
        diffCell = `<span class="text-danger">-${formatShortNumber(Math.abs(diff))}</span>`;
        statusCell = `<span class="badge-pill pill-danger">Thiếu</span>`;
        pctCell = `<span class="text-danger">${percent}%</span>`;
      }

      const dateParts = item.date.split('-');
      const formattedDate = `${dateParts[2]}/${dateParts[1]}/${dateParts[0]}`;

      tr.innerHTML = `
        <td><strong>${formattedDate}</strong></td>
        <td class="text-success"><strong>${formatShortNumber(item.amount)}</strong></td>
        <td>${diffCell}</td>
        <td>${pctCell}</td>
        <td>${statusCell}</td>
        <td><span style="color: var(--text-muted); font-size: 0.8rem;">${item.note || '-'}</span></td>
        <td class="text-right">
          <button class="action-icon edit-btn" data-id="${item.id}" title="Sửa">✏️</button>
          <button class="action-icon delete-btn" data-id="${item.id}" title="Xóa">🗑️</button>
        </td>
      `;

      savingsTableBody.appendChild(tr);
    });

    document.querySelectorAll('.edit-btn').forEach(btn => {
      btn.addEventListener('click', (e) => editEntry(e.currentTarget.dataset.id));
    });

    document.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', (e) => deleteEntry(e.currentTarget.dataset.id));
    });
  }

  function renderChart() {
    const selectedMonth = filterMonthSelect.value;
    if (!selectedMonth) return;

    const [year, month] = selectedMonth.split('-').map(Number);
    const daysInMonth = new Date(year, month, 0).getDate();

    const labels = [];
    const actualData = [];
    const targetData = [];

    const dayMap = {};
    entries.forEach(e => {
      if (e.date && e.date.startsWith(selectedMonth)) {
        const day = parseInt(e.date.split('-')[2]);
        dayMap[day] = e.amount;
      }
    });

    for (let d = 1; d <= daysInMonth; d++) {
      labels.push(`${d}`);
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
            label: 'Đã tiết kiệm',
            data: actualData,
            backgroundColor: actualData.map(v => v >= dailyGoal ? 'rgba(16, 185, 129, 0.8)' : (v > 0 ? 'rgba(239, 68, 68, 0.8)' : 'rgba(148, 163, 184, 0.15)')),
            borderRadius: 4
          },
          {
            label: `Mục tiêu (${formatShortNumber(dailyGoal)})`,
            data: targetData,
            type: 'line',
            borderColor: '#f59e0b',
            borderWidth: 2,
            borderDash: [4, 4],
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
            ticks: { color: '#8b9bb4', callback: v => (v / 1000) + 'k' }
          },
          x: {
            grid: { display: false },
            ticks: { color: '#8b9bb4', font: { size: 10 } }
          }
        },
        plugins: {
          legend: { labels: { color: '#f1f5f9', font: { size: 11 } } }
        }
      }
    });
  }

  // Form Submit
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
      const idx = entries.findIndex(item => item.id === existingId);
      if (idx !== -1) {
        entries[idx] = { id: existingId, date: dateVal, amount: amountVal, note: noteVal };
      }
    } else {
      const existingDateIdx = entries.findIndex(item => item.date === dateVal);
      if (existingDateIdx !== -1) {
        if (confirm(`Ngày ${dateVal} đã có ghi nhận ${formatShortNumber(entries[existingDateIdx].amount)}. Ghi đè số tiền mới ${formatShortNumber(amountVal)}?`)) {
          entries[existingDateIdx].amount = amountVal;
          entries[existingDateIdx].note = noteVal;
        } else {
          return;
        }
      } else {
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
    entryNote.value = 'Thu nhập chạy app';
    saveBtn.textContent = 'Lưu Tiết Kiệm';
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

    saveBtn.textContent = '🔄 Cập Nhật';
    cancelEditBtn.style.display = 'inline-block';

    updateEntryPreview();
    entryAmount.focus();
  }

  function deleteEntry(id) {
    const item = entries.find(e => e.id === id);
    if (!item) return;

    if (confirm(`Xóa ghi nhận ngày ${item.date} (${formatShortNumber(item.amount)})?`)) {
      entries = entries.filter(e => e.id !== id);
      saveToStorage();
      refreshAll();
    }
  }

  cancelEditBtn.addEventListener('click', resetForm);

  // Quick Chips
  document.querySelectorAll('.chip-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.chip-btn').forEach(b => b.classList.remove('active'));
      e.currentTarget.classList.add('active');
      entryAmount.value = e.currentTarget.dataset.val;
      updateEntryPreview();
    });
  });

  entryAmount.addEventListener('input', updateEntryPreview);

  // Tab Switcher
  tabHistoryBtn.addEventListener('click', () => {
    tabHistoryBtn.classList.add('active');
    tabChartBtn.classList.remove('active');
    tabHistoryContent.style.display = 'block';
    tabChartContent.style.display = 'none';
  });

  tabChartBtn.addEventListener('click', () => {
    tabChartBtn.classList.add('active');
    tabHistoryBtn.classList.remove('active');
    tabHistoryContent.style.display = 'none';
    tabChartContent.style.display = 'block';
    renderChart();
  });

  // Goal Modal
  configGoalBtn.addEventListener('click', () => {
    modalGoalInput.value = dailyGoal;
    goalModal.style.display = 'flex';
  });

  closeGoalModalBtn.addEventListener('click', () => {
    goalModal.style.display = 'none';
  });

  saveGoalModalBtn.addEventListener('click', () => {
    const newGoal = parseInt(modalGoalInput.value);
    if (isNaN(newGoal) || newGoal <= 0) return;
    dailyGoal = newGoal;
    saveToStorage();
    goalModal.style.display = 'none';
    updateEntryPreview();
    refreshAll();
  });

  // Export / Import
  exportDataBtn.addEventListener('click', () => {
    const backupData = { version: 1, dailyGoal, exportedAt: new Date().toISOString(), entries };
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(backupData, null, 2));
    const a = document.createElement('a');
    a.href = dataStr;
    a.download = `SaoLuu_TietKiem_${new Date().toISOString().substring(0, 10)}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
  });

  importDataBtn.addEventListener('click', () => importFileInput.click());

  importFileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function (evt) {
      try {
        const imported = JSON.parse(evt.target.result);
        if (imported.entries && Array.isArray(imported.entries)) {
          entries = imported.entries;
          if (imported.dailyGoal) dailyGoal = imported.dailyGoal;
          saveToStorage();
          refreshAll();
          alert('Nhập dữ liệu thành công!');
        }
      } catch (err) {
        alert('File không hợp lệ!');
      }
    };
    reader.readAsText(file);
  });

  clearAllBtn.addEventListener('click', () => {
    if (confirm('Xóa TOÀN BỘ nhật ký tiết kiệm?')) {
      entries = [];
      saveToStorage();
      refreshAll();
    }
  });

  filterMonthSelect.addEventListener('change', () => {
    renderTable();
    if (tabChartContent.style.display !== 'none') {
      renderChart();
    }
  });

  function refreshAll() {
    populateMonthSelect();
    renderDashboard();
    renderTable();
    if (tabChartContent.style.display !== 'none') {
      renderChart();
    }
  }

  seedInitialSampleData();
  setDefaultDate();
  entryAmount.value = dailyGoal;
  updateEntryPreview();
  refreshAll();
})();
