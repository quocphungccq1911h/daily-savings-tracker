// Sổ Tiết Kiệm Daily - Cloud (Supabase) + LocalStorage Hybrid Engine
(function () {
  const STORAGE_KEY = 'savings_tracker_entries_v1';
  const GOAL_STORAGE_KEY = 'savings_tracker_daily_goal_v1';
  const SUPABASE_URL_KEY = 'savings_supabase_url_v1';
  const SUPABASE_KEY_KEY = 'savings_supabase_key_v1';

  let dailyGoal = parseInt(localStorage.getItem(GOAL_STORAGE_KEY)) || 150000;
  let entries = JSON.parse(localStorage.getItem(STORAGE_KEY)) || [];
  let savingsChartInstance = null;

  // PIN Security Cipher Helper
  const PIN_STORAGE_KEY = 'savings_user_pin_v1';
  
  function pinCipher(str, pinStr) {
    let key = 0;
    for (let i = 0; i < pinStr.length; i++) key += pinStr.charCodeAt(i);
    let result = '';
    for (let i = 0; i < str.length; i++) {
      result += String.fromCharCode(str.charCodeAt(i) ^ (key + (i % 7)));
    }
    return result;
  }

  function encryptCloudData(url, key, pin) {
    const raw = JSON.stringify({ u: url, k: key });
    return btoa(encodeURIComponent(pinCipher(raw, pin)));
  }

  function decryptCloudData(encryptedBase64, pin) {
    try {
      const cipher = decodeURIComponent(atob(encryptedBase64));
      const raw = pinCipher(cipher, pin);
      const data = JSON.parse(raw);
      if (data && data.u && data.k) return data;
    } catch (e) {
      return null;
    }
    return null;
  }

  // Default Supabase Credentials (Tự động kết nối vĩnh viễn cho mọi thiết bị)
  const DEFAULT_SUPABASE_URL = 'https://hgpuzvpafpbpaatcutbm.supabase.co';
  const DEFAULT_SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhncHV6dnBhZnBicGFhdGN1dGJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1NjUzNDIsImV4cCI6MjEwMjE0MTM0Mn0.AXXykroFn5jJ69kjol2NrnxxgRt5ctIf7dXSTd6-of0';

  // Supabase Client State
  let supabaseUrl = localStorage.getItem(SUPABASE_URL_KEY) || DEFAULT_SUPABASE_URL;
  let supabaseKey = localStorage.getItem(SUPABASE_KEY_KEY) || DEFAULT_SUPABASE_KEY;
  let supabaseClient = null;
  let isCloudConnected = false;

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

  // Cloud Modal DOM
  const cloudStatusBtn = document.getElementById('cloudStatusBtn');
  const cloudModal = document.getElementById('cloudModal');
  const supabaseUrlInput = document.getElementById('supabaseUrlInput');
  const supabaseKeyInput = document.getElementById('supabaseKeyInput');
  const saveCloudConfigBtn = document.getElementById('saveCloudConfigBtn');
  const disconnectCloudBtn = document.getElementById('disconnectCloudBtn');
  const closeCloudModalBtn = document.getElementById('closeCloudModalBtn');
  const copySqlBtn = document.getElementById('copySqlBtn');

  function formatShortNumber(num) {
    return new Intl.NumberFormat('vi-VN').format(Math.round(num)) + ' đ';
  }

  // --- SUPABASE ENGINE ---
  function initSupabase(retryCount = 0) {
    supabaseUrl = DEFAULT_SUPABASE_URL;
    supabaseKey = DEFAULT_SUPABASE_KEY;

    const lib = window.supabase;
    if (lib && typeof lib.createClient === 'function') {
      try {
        supabaseClient = lib.createClient(supabaseUrl, supabaseKey);
        isCloudConnected = true;
        updateCloudStatusUI(true);
        fetchFromCloud();
        subscribeRealtime();
        return;
      } catch (err) {
        console.error("Supabase init error:", err);
      }
    }
    
    if (retryCount < 30) {
      setTimeout(() => initSupabase(retryCount + 1), 100);
      return;
    }

    isCloudConnected = true;
    updateCloudStatusUI(true);
  }

  function updateCloudStatusUI(connected) {
    if (connected) {
      cloudStatusBtn.className = 'icon-tool-btn cloud-on';
      cloudStatusBtn.innerHTML = '☁️ Cloud Online';
      if (disconnectCloudBtn) disconnectCloudBtn.style.display = 'inline-block';
    } else {
      cloudStatusBtn.className = 'icon-tool-btn cloud-off';
      cloudStatusBtn.innerHTML = '☁️ Off Cloud';
      if (disconnectCloudBtn) disconnectCloudBtn.style.display = 'none';
    }
  }

  async function fetchFromCloud() {
    if (!supabaseClient) return;
    try {
      const { data, error } = await supabaseClient
        .from('savings_entries')
        .select('*')
        .order('entry_date', { ascending: false });

      if (error) throw error;

      if (data && Array.isArray(data)) {
        entries = data.map(item => ({
          id: item.id,
          date: item.entry_date,
          amount: parseInt(item.amount),
          note: item.note || ''
        }));
        saveToStorage();
        refreshAll();
      }
    } catch (err) {
      console.warn("Cloud fetch warning (using LocalStorage):", err.message);
    }
  }

  function subscribeRealtime() {
    if (!supabaseClient) return;
    try {
      supabaseClient
        .channel('public:savings_entries')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'savings_entries' }, () => {
          fetchFromCloud();
        })
        .subscribe();
    } catch (err) {
      console.warn("Realtime sub error:", err);
    }
  }

  function generateUUID() {
    if (window.crypto && typeof window.crypto.randomUUID === 'function') {
      return window.crypto.randomUUID();
    }
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  async function syncSaveToCloud(entryItem) {
    if (!supabaseClient) return;
    try {
      const payload = {
        entry_date: entryItem.date,
        amount: entryItem.amount,
        note: entryItem.note
      };
      if (entryItem.id && !entryItem.id.startsWith('entry-') && !entryItem.id.startsWith('sample-')) {
        payload.id = entryItem.id;
      }
      const { error } = await supabaseClient
        .from('savings_entries')
        .upsert(payload);

      if (error) {
        console.error("Supabase Save Error:", error.message);
      }
    } catch (err) {
      console.error("Cloud save error:", err);
    }
  }

  async function syncDeleteFromCloud(entryIdVal) {
    if (!supabaseClient) return;
    try {
      await supabaseClient
        .from('savings_entries')
        .delete()
        .eq('id', entryIdVal);
    } catch (err) {
      console.error("Cloud delete error:", err);
    }
  }

  // --- LOCAL DATA ENGINE ---
  function seedInitialSampleData() {
    if (entries.length === 0 && !isCloudConnected) {
      const today = new Date();
      const currentYear = today.getFullYear();
      const currentMonthStr = String(today.getMonth() + 1).padStart(2, '0');

      entries = [
        { id: 'sample-1', date: `${currentYear}-${currentMonthStr}-01`, amount: 140000, note: 'Khởi đầu tháng' },
        { id: 'sample-2', date: `${currentYear}-${currentMonthStr}-02`, amount: 160000, note: 'Thu nhập chạy app' },
        { id: 'sample-3', date: `${currentYear}-${currentMonthStr}-03`, amount: 150000, note: 'Thu nhập chạy app' },
        { id: 'sample-4', date: `${currentYear}-${currentMonthStr}-04`, amount: 150000, note: 'Thu nhập chạy app' },
        { id: 'sample-5', date: `${currentYear}-${currentMonthStr}-05`, amount: 200000, note: 'Thu nhập chạy app (+50k)' },
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

  const bannerTitleText = document.getElementById('bannerTitleText');
  const bannerMetaText = document.getElementById('bannerMetaText');

  function renderDashboard() {
    headerGoalDisplay.textContent = formatShortNumber(dailyGoal);

    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;
    const currentDay = now.getDate();
    const currentMonthKey = `${currentYear}-${String(currentMonth).padStart(2, '0')}`;

    const selectedMonthKey = filterMonthSelect.value || currentMonthKey;
    const [selectedYear, selectedMonth] = selectedMonthKey.split('-').map(Number);
    const isCurrentMonth = (selectedMonthKey === currentMonthKey);

    const monthEntries = entries.filter(e => e.date && e.date.startsWith(selectedMonthKey));
    const totalDaysInMonth = new Date(selectedYear, selectedMonth, 0).getDate();

    let monthTotalSaved = 0;
    let savedUpToToday = 0;

    monthEntries.forEach(e => {
      const dayNum = parseInt(e.date.split('-')[2]);
      monthTotalSaved += e.amount;
      if (dayNum <= currentDay) {
        savedUpToToday += e.amount;
      }
    });

    const monthTarget = totalDaysInMonth * dailyGoal;

    if (isCurrentMonth) {
      const cumulativeTargetToToday = currentDay * dailyGoal;
      if (bannerTitleText) bannerTitleText.innerHTML = `LŨY KẾ ĐẾN HÔM NAY (${String(currentDay).padStart(2, '0')}/${String(currentMonth).padStart(2, '0')})`;
      if (bannerMetaText) bannerMetaText.innerHTML = `Mục tiêu lũy kế đến nay: <strong>${formatShortNumber(cumulativeTargetToToday)}</strong>`;

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
    } else {
      if (bannerTitleText) bannerTitleText.innerHTML = `TỔNG KẾT THÁNG ${selectedMonth}/${selectedYear}`;
      if (bannerMetaText) bannerMetaText.innerHTML = `Tổng mục tiêu tháng: <strong>${formatShortNumber(monthTarget)}</strong>`;

      const monthDiff = monthTotalSaved - monthTarget;
      if (monthDiff >= 0) {
        statusPaceAmount.textContent = monthDiff === 0 ? 'Đạt 100% Target' : `+${formatShortNumber(monthDiff)}`;
        statusPaceAmount.className = 'banner-val text-success';
        statusPacePill.textContent = monthDiff === 0 ? 'Vừa đủ mục tiêu tháng' : `🎉 Hoàn thành tháng! Dư +${formatShortNumber(monthDiff)}`;
      } else {
        const diffAbs = Math.abs(monthDiff);
        statusPaceAmount.textContent = `-${formatShortNumber(diffAbs)}`;
        statusPaceAmount.className = 'banner-val text-danger';
        statusPacePill.textContent = `Thiếu -${formatShortNumber(diffAbs)} so với mục tiêu tháng`;
      }
    }

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
      if (isCurrentMonth) {
        const remainingDays = totalDaysInMonth - currentDay;
        if (remainingDays > 0) {
          const requiredDailyAvg = Math.ceil(remainingNeed / remainingDays);
          monthDailyAdvice.innerHTML = `Cần ~<strong>${formatShortNumber(requiredDailyAvg)}/ngày</strong> cho ${remainingDays} ngày còn lại.`;
        } else {
          monthDailyAdvice.innerHTML = `Đã hết tháng. Còn thiếu ${formatShortNumber(remainingNeed)}.`;
        }
      } else {
        monthDailyAdvice.innerHTML = `Kết thúc tháng còn thiếu <strong>${formatShortNumber(remainingNeed)}</strong>.`;
      }
    }

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

    // Group by Date YYYY-MM-DD
    const dailyMap = {};
    filtered.forEach(item => {
      if (!dailyMap[item.date]) {
        dailyMap[item.date] = { date: item.date, total: 0, items: [] };
      }
      dailyMap[item.date].total += item.amount;
      dailyMap[item.date].items.push(item);
    });

    const sortedDates = Object.keys(dailyMap).sort().reverse();

    sortedDates.forEach(dateKey => {
      const group = dailyMap[dateKey];
      const totalAmount = group.total;
      const diff = totalAmount - dailyGoal;
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

      const dateParts = dateKey.split('-');
      const formattedDate = `${dateParts[2]}/${dateParts[1]}/${dateParts[0]}`;

      // Notes formatting (ngắn gọn 1 dòng)
      let notesHtml = '';
      if (group.items.length === 1) {
        notesHtml = `<span style="color: var(--text-muted); font-size: 0.8rem;">${group.items[0].note || '-'}</span>`;
      } else {
        const firstNote = group.items[0].note || 'Thu nhập';
        notesHtml = `<span style="color: #38bdf8; font-size: 0.8rem; font-weight: 500;">${firstNote}</span> <span style="color: var(--text-muted); font-size: 0.775rem;">(+${group.items.length - 1} khoản khác)</span>`;
      }

      // Action buttons
      let actionsHtml = '';
      if (group.items.length === 1) {
        actionsHtml = `
          <button class="action-icon edit-btn" data-id="${group.items[0].id}" title="Sửa">✏️ Sửa</button>
          <button class="action-icon delete-btn" data-id="${group.items[0].id}" title="Xóa">🗑️ Xóa</button>
        `;
      } else {
        actionsHtml = `
          <button class="btn-detail-toggle" data-target="detail-${dateKey}">
            🔍 Xem ${group.items.length} khoản <span class="toggle-icon">▼</span>
          </button>
        `;
      }

      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td data-label="Ngày"><strong>${formattedDate}</strong> ${group.items.length > 1 ? `<span class="badge-pill pill-info" style="font-size: 0.68rem; padding: 1px 5px; margin-left: 4px;">${group.items.length} khoản</span>` : ''}</td>
        <td data-label="Số tiền" class="text-success"><strong>${formatShortNumber(totalAmount)}</strong></td>
        <td data-label="So với 150k">${diffCell}</td>
        <td data-label="% Kỳ vọng">${pctCell}</td>
        <td data-label="Trạng thái">${statusCell}</td>
        <td data-label="Ghi chú">${notesHtml}</td>
        <td data-label="Thao tác" class="text-right">${actionsHtml}</td>
      `;

      savingsTableBody.appendChild(tr);

      // Detail sub-row for multiple entries
      if (group.items.length > 1) {
        const detailTr = document.createElement('tr');
        detailTr.id = `detail-${dateKey}`;
        detailTr.style.display = 'none';
        detailTr.className = 'detail-row';

        const subItemsHtml = group.items.map((sub, idx) => `
          <div class="sub-entry-item">
            <span class="sub-idx">#${idx + 1}</span>
            <span class="sub-amount">${formatShortNumber(sub.amount)}</span>
            <span class="sub-note" title="${sub.note || 'Thu nhập'}">${sub.note || 'Thu nhập chạy app'}</span>
            <div class="sub-actions">
              <button class="action-icon edit-btn" data-id="${sub.id}">✏️ Sửa</button>
              <button class="action-icon delete-btn" data-id="${sub.id}">🗑️ Xóa</button>
            </div>
          </div>
        `).join('');

        detailTr.innerHTML = `
          <td colspan="7" style="padding: 0; border-top: none;">
            <div class="sub-entries-container">
              <div style="font-size: 0.775rem; font-weight: 700; color: #38bdf8; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
                <span>📋 CHI TIẾT ${group.items.length} KHOẢN THU NHẬP NGÀY ${formattedDate}:</span>
                <span style="font-size: 0.75rem; color: #34d399;">Tổng: ${formatShortNumber(totalAmount)}</span>
              </div>
              <div class="sub-entries-list">
                ${subItemsHtml}
              </div>
            </div>
          </td>
        `;

        savingsTableBody.appendChild(detailTr);
      }
    });

    // Detail Toggle listener
    document.querySelectorAll('.btn-detail-toggle').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const targetId = e.currentTarget.dataset.target;
        const detailRow = document.getElementById(targetId);
        if (detailRow) {
          const isHidden = (detailRow.style.display === 'none');
          detailRow.style.display = isHidden ? 'table-row' : 'none';
          e.currentTarget.classList.toggle('active', isHidden);
          const icon = e.currentTarget.querySelector('.toggle-icon');
          if (icon) icon.textContent = isHidden ? '▲' : '▼';
        }
      });
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
        dayMap[day] = (dayMap[day] || 0) + e.amount;
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

    const newEntry = {
      id: existingId || generateUUID(),
      date: dateVal,
      amount: amountVal,
      note: noteVal
    };

    if (existingId) {
      const idx = entries.findIndex(item => item.id === existingId);
      if (idx !== -1) entries[idx] = newEntry;
    } else {
      entries.push(newEntry);
    }

    saveToStorage();
    syncSaveToCloud(newEntry);
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
      syncDeleteFromCloud(item.date);
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

  // PIN Modal Elements
  const pinModal = document.getElementById('pinModal');
  const pinInput = document.getElementById('pinInput');
  const submitPinBtn = document.getElementById('submitPinBtn');
  const pinErrorMsg = document.getElementById('pinErrorMsg');

  // Cloud Modal Handlers
  cloudStatusBtn.addEventListener('click', () => {
    if (!isCloudConnected) {
      const encryptedData = localStorage.getItem('savings_encrypted_cloud_v1');
      if (encryptedData) {
        pinInput.value = '';
        pinErrorMsg.style.display = 'none';
        pinModal.style.display = 'flex';
        return;
      }
    }
    supabaseUrlInput.value = supabaseUrl;
    supabaseKeyInput.value = supabaseKey;
    cloudModal.style.display = 'flex';
  });

  submitPinBtn.addEventListener('click', () => {
    const pin = pinInput.value.trim();
    const encryptedData = localStorage.getItem('savings_encrypted_cloud_v1');
    if (!pin || !encryptedData) return;

    const decrypted = decryptCloudData(encryptedData, pin);
    if (decrypted) {
      supabaseUrl = decrypted.u;
      supabaseKey = decrypted.k;
      localStorage.setItem(SUPABASE_URL_KEY, supabaseUrl);
      localStorage.setItem(SUPABASE_KEY_KEY, supabaseKey);
      pinModal.style.display = 'none';
      initSupabase();
      alert('🔓 Mở khóa CSDL Đám mây thành công!');
    } else {
      pinErrorMsg.style.display = 'block';
    }
  });

  closeCloudModalBtn.addEventListener('click', () => {
    cloudModal.style.display = 'none';
  });

    const ENCRYPTED_CLOUD_KEY = 'savings_encrypted_cloud_v1';

    saveCloudConfigBtn.addEventListener('click', () => {
    const url = supabaseUrlInput.value.trim();
    const key = supabaseKeyInput.value.trim();

    if (!url || !key) {
      alert('Vui lòng nhập đầy đủ Supabase URL và Anon Key!');
      return;
    }

    supabaseUrl = url;
    supabaseKey = key;
    localStorage.setItem(SUPABASE_URL_KEY, supabaseUrl);
    localStorage.setItem(SUPABASE_KEY_KEY, supabaseKey);

    cloudModal.style.display = 'none';
    initSupabase();
    alert('⚡ Đã lưu và kết nối CSDL Cloud thành công!');
  });

  disconnectCloudBtn.addEventListener('click', () => {
    if (confirm('Bạn có chắc chắn muốn ngắt kết nối Cloud không? (Dữ liệu vẫn được giữ trong máy)')) {
      supabaseUrl = '';
      supabaseKey = '';
      localStorage.removeItem(SUPABASE_URL_KEY);
      localStorage.removeItem(SUPABASE_KEY_KEY);
      supabaseClient = null;
      isCloudConnected = false;
      updateCloudStatusUI(false);
      cloudModal.style.display = 'none';
    }
  });

  copySqlBtn.addEventListener('click', () => {
    const sqlText = `create table if not exists savings_entries (
  id uuid primary key default gen_random_uuid(),
  entry_date date unique not null,
  amount bigint not null,
  note text default 'Thu nhập chạy app',
  created_at timestamptz default now()
);

alter table savings_entries enable row level security;
create policy "Public Access" on savings_entries for all using (true) with check (true);`;

    navigator.clipboard.writeText(sqlText).then(() => {
      alert('Đã copy mã SQL! Hãy dán vào SQL Editor trên Supabase.');
    });
  });

  clearAllBtn.addEventListener('click', () => {
    if (confirm('⚠️ CẢNH BÁO NGUY HIỂM: Bạn có chắc chắn muốn xóa TOÀN BỘ nhật ký tiết kiệm không? Hành động này không thể hoàn tác!')) {
      const confirmInput = prompt('Để xác nhận xóa toàn bộ dữ liệu, vui lòng gõ chữ "XÓA" vào ô dưới đây:');
      if (confirmInput && confirmInput.trim().toUpperCase() === 'XÓA') {
        entries = [];
        saveToStorage();
        refreshAll();
        alert('Đã xóa toàn bộ nhật ký tiết kiệm!');
      } else if (confirmInput !== null) {
        alert('Mã xác nhận không đúng. Đã hủy thao tác xóa.');
      }
    }
  });

  filterMonthSelect.addEventListener('change', () => {
    renderDashboard();
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

  // App Initialize
  initSupabase();
  seedInitialSampleData();
  setDefaultDate();
  entryAmount.value = dailyGoal;
  updateEntryPreview();
  refreshAll();

  // Retry on window load for local file:/// protocol
  window.addEventListener('load', () => {
    initSupabase();
  });
})();
