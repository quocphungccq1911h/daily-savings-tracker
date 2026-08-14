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
  const formHeaderToggle = document.getElementById('formHeaderToggle');
  const toggleFormBtn = document.getElementById('toggleFormBtn');
  const toggleFormText = document.getElementById('toggleFormText');
  const toggleFormIcon = document.getElementById('toggleFormIcon');
  const formBodyWrap = document.getElementById('formBodyWrap');
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
  const tabBadgesBtn = document.getElementById('tabBadgesBtn');
  const tabWishlistBtn = document.getElementById('tabWishlistBtn');
  const tabHistoryContent = document.getElementById('tabHistoryContent');
  const tabChartContent = document.getElementById('tabChartContent');
  const tabBadgesContent = document.getElementById('tabBadgesContent');
  const tabWishlistContent = document.getElementById('tabWishlistContent');

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

  // Auth State & DOM
  let currentUser = null;
  let isSignUpMode = false;

  const userProfileBadge = document.getElementById('userProfileBadge');
  const userEmailText = document.getElementById('userEmailText');
  const signOutBtn = document.getElementById('signOutBtn');

  const authScreenModal = document.getElementById('authScreenModal');
  const authTitle = document.getElementById('authTitle');
  const authSubTitle = document.getElementById('authSubTitle');
  const authAlertBox = document.getElementById('authAlertBox');
  const authForm = document.getElementById('authForm');
  const authEmailInput = document.getElementById('authEmailInput');
  const authPasswordInput = document.getElementById('authPasswordInput');
  const authSubmitBtn = document.getElementById('authSubmitBtn');
  const authToggleQuestion = document.getElementById('authToggleQuestion');
  const toggleAuthModeBtn = document.getElementById('toggleAuthModeBtn');

  function showAuthAlert(msg, isError = true) {
    authAlertBox.style.display = 'block';
    authAlertBox.style.background = isError ? 'rgba(239, 68, 68, 0.15)' : 'rgba(16, 185, 129, 0.15)';
    authAlertBox.style.border = isError ? '1px solid #f87171' : '1px solid #34d399';
    authAlertBox.style.color = isError ? '#fca5a5' : '#a7f3d0';
    authAlertBox.textContent = msg;
  }

  function hideAuthAlert() {
    authAlertBox.style.display = 'none';
  }

  function toggleAuthMode() {
    isSignUpMode = !isSignUpMode;
    hideAuthAlert();
    if (isSignUpMode) {
      authTitle.textContent = '📝 Tạo Tài Khoản Mới';
      authSubTitle.textContent = 'Nhập email và mật khẩu của bạn để đăng ký tài khoản tiết kiệm cá nhân.';
      authSubmitBtn.textContent = '✨ Đăng Ký Ngay';
      authToggleQuestion.textContent = 'Đã có tài khoản?';
      toggleAuthModeBtn.textContent = 'Đăng nhập tại đây';
    } else {
      authTitle.textContent = '🔑 Đăng Nhập Sổ Tiết Kiệm';
      authSubTitle.textContent = 'Vui lòng đăng nhập tài khoản cá nhân để xem và lưu dữ liệu bảo mật.';
      authSubmitBtn.textContent = '🔑 Đăng Nhập';
      authToggleQuestion.textContent = 'Chưa có tài khoản?';
      toggleAuthModeBtn.textContent = 'Tạo tài khoản mới';
    }
  }

  async function checkAuthSession() {
    if (!supabaseClient) return;
    try {
      const { data: { session } } = await supabaseClient.auth.getSession();
      if (session && session.user) {
        onUserLoggedIn(session.user);
      } else {
        onUserLoggedOut();
      }
    } catch (e) {
      onUserLoggedOut();
    }
  }

  function setupAuthListener() {
    if (!supabaseClient) return;
    supabaseClient.auth.onAuthStateChange((event, session) => {
      if (session && session.user) {
        onUserLoggedIn(session.user);
      } else {
        onUserLoggedOut();
      }
    });
  }

  const rememberMeCheckbox = document.getElementById('rememberMeCheckbox');
  const REMEMBER_EMAIL_KEY = 'savings_remembered_email_v1';
  const REMEMBER_PASS_KEY = 'savings_remembered_pass_v1';

  function fillRememberedCredentials() {
    const savedEmail = localStorage.getItem(REMEMBER_EMAIL_KEY);
    const savedPass = localStorage.getItem(REMEMBER_PASS_KEY);
    if (savedEmail && authEmailInput) authEmailInput.value = savedEmail;
    if (savedPass && authPasswordInput) authPasswordInput.value = savedPass;
  }

  let realtimeChannel = null;

  function onUserLoggedIn(user) {
    currentUser = user;
    userEmailText.textContent = user.email;
    userProfileBadge.style.display = 'flex';
    authScreenModal.style.display = 'none';
    fetchFromCloud();
    subscribeRealtime();
  }

  function onUserLoggedOut() {
    currentUser = null;
    if (realtimeChannel && supabaseClient) {
      try { supabaseClient.removeChannel(realtimeChannel); } catch (e) {}
      realtimeChannel = null;
    }
    userProfileBadge.style.display = 'none';
    authScreenModal.style.display = 'flex';
    fillRememberedCredentials();
    entries = [];
    refreshAll();
  }

  // --- SUPABASE ENGINE ---
  function initSupabase(retryCount = 0) {
    if (supabaseClient) return;

    supabaseUrl = DEFAULT_SUPABASE_URL;
    supabaseKey = DEFAULT_SUPABASE_KEY;

    const lib = window.supabase;
    if (lib && typeof lib.createClient === 'function') {
      try {
        supabaseClient = lib.createClient(supabaseUrl, supabaseKey);
        isCloudConnected = true;
        updateCloudStatusUI(true);
        checkAuthSession();
        setupAuthListener();
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

  function parseEntryCategory(item) {
    if (item && item.category) {
      return item.category === 'Thu nhập khác' ? 'Khác' : item.category;
    }
    if (item && item.note) {
      const match = item.note.match(/^\[(.*?)\]/);
      if (match && match[1]) {
        return match[1] === 'Thu nhập khác' ? 'Khác' : match[1];
      }
      if (item.note.includes('Grab')) return 'Grab / Chạy xe';
      if (item.note.includes('Lương')) return 'Lương cố định';
      if (item.note.includes('Thưởng')) return 'Thưởng';
    }
    return 'Khác';
  }

  async function fetchFromCloud() {
    if (!supabaseClient || !currentUser) return;
    try {
      const { data, error } = await supabaseClient
        .from('savings_entries')
        .select('*')
        .eq('user_id', currentUser.id)
        .order('entry_date', { ascending: false });

      if (error) throw error;

      if (data && Array.isArray(data)) {
        entries = data.map(item => ({
          id: item.id,
          date: item.entry_date,
          amount: parseInt(item.amount),
          category: item.category || parseEntryCategory(item),
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
    if (!supabaseClient || !currentUser) return;
    try {
      if (realtimeChannel) {
        try { supabaseClient.removeChannel(realtimeChannel); } catch (e) {}
        realtimeChannel = null;
      }
      realtimeChannel = supabaseClient
        .channel(`user-entries-${currentUser.id}`)
        .on('postgres_changes', { event: '*', schema: 'public', table: 'savings_entries', filter: `user_id=eq.${currentUser.id}` }, () => {
          fetchFromCloud();
        });
      realtimeChannel.subscribe();
    } catch (err) {
      console.warn("Realtime sub warning:", err.message);
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
    if (!supabaseClient || !currentUser) return;
    try {
      const catTag = entryItem.category ? `[${entryItem.category}] ` : '';
      const cleanNote = (entryItem.note || '').replace(/^\[.*?\]\s*/, '');
      const fullNote = `${catTag}${cleanNote}`.trim();

      const payload = {
        user_id: currentUser.id,
        entry_date: entryItem.date,
        amount: entryItem.amount,
        note: fullNote
      };
      if (entryItem.id && !entryItem.id.startsWith('entry-') && !entryItem.id.startsWith('sample-')) {
        payload.id = entryItem.id;
      }
      const { error } = await supabaseClient
        .from('savings_entries')
        .upsert(payload);

      if (error) console.error("Cloud save warning:", error.message);
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

  function parseMoneyValue(val) {
    if (val === null || val === undefined) return 0;
    const cleanStr = String(val).replace(/[^\d]/g, '');
    return cleanStr ? parseInt(cleanStr, 10) : 0;
  }

  function formatMoneyInput(val) {
    const num = parseMoneyValue(val);
    return num > 0 ? num.toLocaleString('vi-VN') : '';
  }

  function updateEntryPreview() {
    const val = parseMoneyValue(entryAmount.value);
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
  const streakBadgeBox = document.getElementById('streakBadgeBox');

  function calculateStreak() {
    if (!entries || entries.length === 0) return 0;

    const dayTotals = {};
    entries.forEach(e => {
      if (e.date) {
        dayTotals[e.date] = (dayTotals[e.date] || 0) + e.amount;
      }
    });

    let streak = 0;
    const now = new Date();
    let checkDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const formatDateKey = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    
    let keyToday = formatDateKey(checkDate);
    
    if (!dayTotals[keyToday] || dayTotals[keyToday] < dailyGoal) {
      checkDate.setDate(checkDate.getDate() - 1);
    }

    while (true) {
      const key = formatDateKey(checkDate);
      const dayTotal = dayTotals[key] || 0;
      if (dayTotal >= dailyGoal) {
        streak++;
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        break;
      }
    }

    return streak;
  }

  function renderDashboard() {
    headerGoalDisplay.textContent = formatShortNumber(dailyGoal);

    const streak = calculateStreak();
    if (streakBadgeBox) {
      streakBadgeBox.textContent = `🔥 Chuỗi ${streak} ngày`;
      if (streak >= 3) {
        streakBadgeBox.className = 'streak-badge active-streak';
      } else {
        streakBadgeBox.className = 'streak-badge';
      }
    }

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

    renderMilestoneBadges();
    renderWishlistGoals();
  }

  const MILESTONE_BADGES = [
    { id: 'b1', name: 'Khởi Đầu', amount: 1000000, icon: '🥉' },
    { id: 'b2', name: 'Tiến Bộ', amount: 3000000, icon: '🥈' },
    { id: 'b3', name: 'Tích Lũy', amount: 5000000, icon: '🌟' },
    { id: 'b4', name: 'Bậc Thầy', amount: 10000000, icon: '🥇' },
    { id: 'b5', name: 'Triệu Phú', amount: 50000000, icon: '💎' },
    { id: 'b6', name: 'Đại Phú Hộ', amount: 100000000, icon: '👑' },
    { id: 'b7', name: 'Tỷ Phú Tương Lai', amount: 500000000, icon: '🚀' },
    { id: 'b8', name: 'Huyền Thoại Bất Tử', amount: 1000000000, icon: '🏛️' }
  ];

  const badgesUnlockedBadge = document.getElementById('badgesUnlockedBadge');
  const lifetimeTotalDisplay = document.getElementById('lifetimeTotalDisplay');

  function renderMilestoneBadges() {
    const badgesGridContainer = document.getElementById('badgesGridContainer');
    if (!badgesGridContainer) return;

    const totalLifetimeSaved = entries.reduce((sum, e) => sum + (e.amount || 0), 0);
    if (lifetimeTotalDisplay) lifetimeTotalDisplay.textContent = formatShortNumber(totalLifetimeSaved);

    let unlockedCount = 0;

    const html = MILESTONE_BADGES.map(badge => {
      const isUnlocked = totalLifetimeSaved >= badge.amount;
      if (isUnlocked) unlockedCount++;

      const pct = Math.min(100, Math.round((totalLifetimeSaved / badge.amount) * 100));

      return `
        <div class="badge-tab-card ${isUnlocked ? 'badge-unlocked' : 'badge-locked'}">
          <div class="badge-card-top">
            <div class="badge-card-icon">${badge.icon}</div>
            <div class="badge-card-title">
              <span class="badge-card-name">${badge.name}</span>
              <span class="badge-card-target">Mục tiêu: ${formatShortNumber(badge.amount)}</span>
            </div>
          </div>
          <div class="badge-progress-track">
            <div class="badge-progress-fill" style="width: ${pct}%;"></div>
          </div>
          <div class="badge-card-foot">
            <span class="badge-card-status">${isUnlocked ? '🎉 ✓ Đã Hoàn Thành' : '🔒 Khóa (' + pct + '%)'}</span>
            <span style="color: var(--text-muted); font-size: 0.68rem;">${isUnlocked ? formatShortNumber(badge.amount) : 'Thiếu ' + formatShortNumber(badge.amount - totalLifetimeSaved)}</span>
          </div>
        </div>
      `;
    }).join('');

    badgesGridContainer.innerHTML = html;
    if (badgesUnlockedBadge) {
      badgesUnlockedBadge.textContent = `${unlockedCount}/${MILESTONE_BADGES.length}`;
    }
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

  function cleanUserNote(noteStr) {
    if (!noteStr) return '';
    let s = noteStr.replace(/^\[.*?\]\s*/, '').trim();
    if (s === 'Thu nhập' || s === 'Thu nhập chạy app' || s === 'Thu nhập app') {
      return '';
    }
    return s.replace(/^Thu nhập chạy app\s*/i, '').replace(/^Thu nhập\s*/i, '').trim();
  }

      // Notes formatting (Chỉ hiển thị Tag Nguồn Thu + Ghi chú nếu có)
      let notesHtml = '';
      if (group.items.length === 1) {
        const itemCat = group.items[0].category || parseEntryCategory(group.items[0]);
        const cleanNote = cleanUserNote(group.items[0].note);
        notesHtml = `<span class="badge-category-tag">${itemCat}</span>${cleanNote ? `<span style="color: var(--text-muted); font-size: 0.8rem; margin-left: 4px;">${cleanNote}</span>` : ''}`;
      } else {
        const firstCat = group.items[0].category || parseEntryCategory(group.items[0]);
        const firstNote = cleanUserNote(group.items[0].note);
        notesHtml = `<span class="badge-category-tag">${firstCat}</span>${firstNote ? `<span style="color: #38bdf8; font-size: 0.8rem; font-weight: 500; margin-left: 4px;">${firstNote}</span> ` : ''}<span style="color: var(--text-muted); font-size: 0.775rem;">(+${group.items.length - 1} khoản khác)</span>`;
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

        const subItemsHtml = group.items.map((sub, idx) => {
          const cat = sub.category || parseEntryCategory(sub);
          const cleanNote = cleanUserNote(sub.note);
          return `
          <div class="sub-entry-item">
            <div class="sub-entry-top">
              <div class="sub-entry-left">
                <span class="sub-idx">#${idx + 1}</span>
                <span class="badge-category-tag">${cat}</span>
                <span class="sub-amount">${formatShortNumber(sub.amount)}</span>
              </div>
              <div class="sub-actions">
                <button class="action-icon edit-btn" data-id="${sub.id}">✏️ Sửa</button>
                <button class="action-icon delete-btn" data-id="${sub.id}">🗑️ Xóa</button>
              </div>
            </div>
            ${cleanNote ? `<div class="sub-note">📝 ${cleanNote}</div>` : ''}
          </div>
        `;
        }).join('');

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

    // Render Category Pie Chart alongside Bar Chart
    renderCategoryPieChart(selectedMonth);
  }

  // Category Pill Selector Engine
  const categoryPillsWrap = document.getElementById('categoryPillsWrap');
  const entryCategory = document.getElementById('entryCategory');

  if (categoryPillsWrap) {
    categoryPillsWrap.addEventListener('click', (e) => {
      const btn = e.target.closest('.category-pill');
      if (!btn) return;
      document.querySelectorAll('.category-pill').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      if (entryCategory) entryCategory.value = btn.dataset.category || 'Grab / Chạy xe';
    });
  }

  function setSelectedCategoryUI(catName) {
    const pills = document.querySelectorAll('.category-pill');
    let found = false;
    pills.forEach(p => {
      if (p.dataset.category === catName) {
        p.classList.add('active');
        found = true;
      } else {
        p.classList.remove('active');
      }
    });
    if (!found) {
      const defaultPill = Array.from(pills).find(p => p.dataset.category === 'Grab / Chạy xe') || pills[0];
      if (defaultPill) defaultPill.classList.add('active');
    }
    if (entryCategory) entryCategory.value = found ? catName : 'Grab / Chạy xe';
  }

  let categoryPieChartInstance = null;

  function renderCategoryPieChart(selectedMonthKey) {
    const ctx = document.getElementById('categoryPieChart');
    if (!ctx) return;

    const monthEntries = entries.filter(e => e.date && e.date.startsWith(selectedMonthKey));

    const categoryTotals = {
      'Grab / Chạy xe': 0,
      'Lương cố định': 0,
      'Thưởng': 0,
      'Thu nhập khác': 0
    };

    monthEntries.forEach(item => {
      const cat = item.category || parseEntryCategory(item);
      if (categoryTotals.hasOwnProperty(cat)) {
        categoryTotals[cat] += item.amount;
      } else {
        categoryTotals['Thu nhập khác'] += item.amount;
      }
    });

    const labels = Object.keys(categoryTotals);
    const dataValues = Object.values(categoryTotals);
    const totalMonthAmount = dataValues.reduce((a, b) => a + b, 0);

    if (categoryPieChartInstance) {
      categoryPieChartInstance.destroy();
    }

    if (totalMonthAmount === 0) {
      categoryPieChartInstance = new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: ['Chưa có dữ liệu'],
          datasets: [{
            data: [1],
            backgroundColor: ['rgba(255, 255, 255, 0.08)'],
            borderWidth: 0
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: { legend: { display: false } }
        }
      });
      return;
    }

    categoryPieChartInstance = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{
          data: dataValues,
          backgroundColor: [
            '#10b981', // Grab - Emerald green
            '#38bdf8', // Lương - Sky blue
            '#f59e0b', // Thưởng - Gold
            '#a855f7'  // Khác - Purple
          ],
          borderWidth: 2,
          borderColor: '#0f172a'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#94a3b8',
              font: { size: 10, weight: '600' },
              padding: 8,
              boxWidth: 12
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed;
                const pct = ((val / totalMonthAmount) * 100).toFixed(1);
                return `${context.label}: ${val.toLocaleString('vi-VN')}đ (${pct}%)`;
              }
            }
          }
        }
      }
    });
  }

  // --- TOAST NOTIFICATION ENGINE ---
  function showToast(message, icon = '✅') {
    let toast = document.getElementById('toastNotification');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'toastNotification';
      toast.className = 'toast-notification';
      document.body.appendChild(toast);
    }
    toast.innerHTML = `<span>${icon}</span> <span>${message}</span>`;
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 2800);
  }

  // --- COLLAPSIBLE FORM ENGINE ---
  let isFormOpen = window.innerWidth > 768; // Open on Desktop, Collapsed by default on Mobile!

  function updateFormStateUI() {
    if (!formBodyWrap) return;
    if (isFormOpen) {
      formBodyWrap.classList.remove('collapsed');
      if (toggleFormBtn) toggleFormBtn.classList.add('open');
      if (toggleFormText) toggleFormText.textContent = 'Thu Gọn';
    } else {
      formBodyWrap.classList.add('collapsed');
      if (toggleFormBtn) toggleFormBtn.classList.remove('open');
      if (toggleFormText) toggleFormText.textContent = '➕ Thêm Khoản Mới';
    }
  }

  function toggleFormState() {
    isFormOpen = !isFormOpen;
    updateFormStateUI();
  }

  if (formHeaderToggle) {
    formHeaderToggle.addEventListener('click', () => toggleFormState());
  }

  // Initialize Form Collapsed State
  updateFormStateUI();

  // --- TOUCH DRAG GUARDRAIL FOR SAVE BUTTON ---
  let touchStartY = 0;
  let touchStartX = 0;
  let isDraggingTouch = false;

  if (saveBtn) {
    saveBtn.addEventListener('touchstart', (e) => {
      if (e.touches && e.touches[0]) {
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
        isDraggingTouch = false;
      }
    }, { passive: true });

    saveBtn.addEventListener('touchmove', (e) => {
      if (e.touches && e.touches[0]) {
        const moveX = Math.abs(e.touches[0].clientX - touchStartX);
        const moveY = Math.abs(e.touches[0].clientY - touchStartY);
        if (moveX > 10 || moveY > 10) {
          isDraggingTouch = true;
        }
      }
    }, { passive: true });
  }

  // Form Submit
  savingsForm.addEventListener('submit', (e) => {
    e.preventDefault();
    if (isDraggingTouch) {
      isDraggingTouch = false;
      return; // Ignore submit if user was scrolling/dragging thumb across button!
    }

    const dateVal = entryDate.value;
    const amountVal = parseMoneyValue(entryAmount.value);
    const noteVal = entryNote.value.trim() || 'Thu nhập';
    const catVal = entryCategory ? entryCategory.value : 'Grab / Chạy xe';
    const existingId = entryId.value;

    if (!dateVal || isNaN(amountVal) || amountVal < 0) {
      alert('Vui lòng nhập ngày và số tiền hợp lệ!');
      return;
    }

    const newEntry = {
      id: existingId || generateUUID(),
      date: dateVal,
      amount: amountVal,
      category: catVal,
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

    const actionMsg = existingId ? 'Cập nhật thành công' : 'Đã lưu khoản ' + formatShortNumber(amountVal);
    showToast(actionMsg, '🎉');

    resetForm();
    refreshAll();

    // Auto collapse form on mobile after saving to prevent accidental taps while scrolling!
    if (window.innerWidth <= 768) {
      isFormOpen = false;
      updateFormStateUI();
    }
  });

  function resetForm() {
    entryId.value = '';
    entryAmount.value = formatMoneyInput(150000);
    entryNote.value = '';
    setSelectedCategoryUI('Grab / Chạy xe');
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
    entryAmount.value = formatMoneyInput(item.amount);
    entryNote.value = item.note || '';

    saveBtn.textContent = '🔄 Cập Nhật';

    // Auto expand form when editing an entry!
    isFormOpen = true;
    updateFormStateUI();
    cancelEditBtn.style.display = 'inline-block';

    updateEntryPreview();
    entryAmount.focus();
  }

  function deleteEntry(id) {
    const item = entries.find(e => e.id === id);
    if (!item) return;

    if (confirm(`Xóa khoản tiết kiệm "${item.note || 'Thu nhập'}" (${formatShortNumber(item.amount)})?`)) {
      entries = entries.filter(e => e.id !== id);
      saveToStorage();
      syncDeleteFromCloud(item.id);
      refreshAll();
    }
  }

  cancelEditBtn.addEventListener('click', resetForm);

  // Quick Chips
  document.querySelectorAll('.chip-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.chip-btn').forEach(b => b.classList.remove('active'));
      e.currentTarget.classList.add('active');
      entryAmount.value = formatMoneyInput(e.currentTarget.dataset.val);
      updateEntryPreview();
    });
  });

  entryAmount.addEventListener('input', () => {
    const formatted = formatMoneyInput(entryAmount.value);
    entryAmount.value = formatted;
    updateEntryPreview();
  });

  // Tab Switcher
  tabHistoryBtn.addEventListener('click', () => {
    tabHistoryBtn.classList.add('active');
    tabChartBtn.classList.remove('active');
    if (tabBadgesBtn) tabBadgesBtn.classList.remove('active');
    if (tabWishlistBtn) tabWishlistBtn.classList.remove('active');
    tabHistoryContent.style.display = 'block';
    tabChartContent.style.display = 'none';
    if (tabBadgesContent) tabBadgesContent.style.display = 'none';
    if (tabWishlistContent) tabWishlistContent.style.display = 'none';
  });

  tabChartBtn.addEventListener('click', () => {
    tabChartBtn.classList.add('active');
    tabHistoryBtn.classList.remove('active');
    if (tabBadgesBtn) tabBadgesBtn.classList.remove('active');
    if (tabWishlistBtn) tabWishlistBtn.classList.remove('active');
    tabHistoryContent.style.display = 'none';
    tabChartContent.style.display = 'block';
    if (tabBadgesContent) tabBadgesContent.style.display = 'none';
    if (tabWishlistContent) tabWishlistContent.style.display = 'none';
    renderChart();
  });

  if (tabBadgesBtn) {
    tabBadgesBtn.addEventListener('click', () => {
      tabBadgesBtn.classList.add('active');
      tabHistoryBtn.classList.remove('active');
      tabChartBtn.classList.remove('active');
      if (tabWishlistBtn) tabWishlistBtn.classList.remove('active');
      tabHistoryContent.style.display = 'none';
      tabChartContent.style.display = 'none';
      tabBadgesContent.style.display = 'block';
      if (tabWishlistContent) tabWishlistContent.style.display = 'none';
      renderMilestoneBadges();
    });
  }

  if (tabWishlistBtn) {
    tabWishlistBtn.addEventListener('click', () => {
      tabWishlistBtn.classList.add('active');
      tabHistoryBtn.classList.remove('active');
      tabChartBtn.classList.remove('active');
      if (tabBadgesBtn) tabBadgesBtn.classList.remove('active');
      tabHistoryContent.style.display = 'none';
      tabChartContent.style.display = 'none';
      if (tabBadgesContent) tabBadgesContent.style.display = 'none';
      tabWishlistContent.style.display = 'block';
      renderWishlistGoals();
    });
  }

  // --- WISHLIST TARGET GOALS ENGINE ---
  const WISHLIST_KEY = 'savings_wishlist_goals_v1';

  const DEFAULT_WISHLIST_GOALS = [
    { id: 'w1', title: 'Xây nhà / Mua nhà', targetAmount: 500000000, allocatedAmount: 0, emoji: '🏠' },
    { id: 'w2', title: 'Mua đất', targetAmount: 200000000, allocatedAmount: 0, emoji: '🏞️' },
    { id: 'w3', title: 'Quỹ dự phòng khẩn cấp', targetAmount: 10000000, allocatedAmount: 0, emoji: '🛡️' }
  ];

  let wishlistGoals = [];

  function loadWishlistGoals() {
    try {
      const saved = localStorage.getItem(WISHLIST_KEY);
      if (saved) {
        let parsed = JSON.parse(saved);
        if (parsed.some(g => g.id === 'w4' || g.title === 'Đổi iPhone 16 Pro' || g.title === 'Mua Xe máy mới')) {
          wishlistGoals = DEFAULT_WISHLIST_GOALS;
          localStorage.setItem(WISHLIST_KEY, JSON.stringify(wishlistGoals));
        } else {
          wishlistGoals = parsed;
        }
      } else {
        wishlistGoals = DEFAULT_WISHLIST_GOALS;
      }
    } catch (e) {
      wishlistGoals = DEFAULT_WISHLIST_GOALS;
    }
  }

  function saveWishlistGoals() {
    localStorage.setItem(WISHLIST_KEY, JSON.stringify(wishlistGoals));
    renderWishlistGoals();
  }

  function renderWishlistGoals() {
    const wishlistGridContainer = document.getElementById('wishlistGridContainer');
    const wishlistCountBadge = document.getElementById('wishlistCountBadge');
    if (!wishlistGridContainer) return;

    let totalLifetimeSaved = 0;
    entries.forEach(e => totalLifetimeSaved += (e.amount || 0));

    if (wishlistCountBadge) {
      wishlistCountBadge.textContent = wishlistGoals.length.toString();
    }

    const now = new Date();
    const daysPassed = now.getDate();
    let currentMonthSaved = 0;
    const currentMonthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    entries.filter(e => e.date && e.date.startsWith(currentMonthKey)).forEach(e => currentMonthSaved += e.amount);
    const avgDailyPace = daysPassed > 0 ? Math.round(currentMonthSaved / daysPassed) : dailyGoal;
    const effectivePace = Math.max(avgDailyPace, dailyGoal);

    if (wishlistGoals.length === 0) {
      wishlistGridContainer.innerHTML = `
        <div style="grid-column: 1 / -1; text-align: center; padding: 24px; color: var(--text-muted);">
          Chưa có mục tiêu ước mơ nào. Hãy bấm "➕ Thêm Mục Tiêu Mới" để đặt mục tiêu nhé!
        </div>
      `;
      return;
    }

    const html = wishlistGoals.map(item => {
      const allocated = item.allocatedAmount || 0;
      const currentSaved = Math.min(item.targetAmount, Math.max(allocated, totalLifetimeSaved));
      const pct = Math.min(100, Math.round((currentSaved / item.targetAmount) * 100));
      const isCompleted = pct >= 100;
      const remaining = Math.max(0, item.targetAmount - currentSaved);

      let forecastText = '';
      if (isCompleted) {
        forecastText = '🎉 CHÚC MỪNG! ĐÃ HOÀN THÀNH MỤC TIÊU!';
      } else {
        const daysNeeded = Math.ceil(remaining / effectivePace);
        forecastText = `🚀 Còn thiếu ${formatShortNumber(remaining)} — Dự kiến đạt sau ~<strong>${daysNeeded} ngày</strong> (Tốc độ: ${formatShortNumber(effectivePace)}/ngày)`;
      }

      return `
        <div class="wishlist-card ${isCompleted ? 'completed' : ''}">
          <div class="wishlist-card-top">
            <div class="wishlist-card-brand">
              <span class="wishlist-card-icon">${item.emoji || '🏠'}</span>
              <div>
                <div class="wishlist-card-title">${item.title}</div>
                <div class="wishlist-card-target">Mục tiêu: ${formatShortNumber(item.targetAmount)}</div>
              </div>
            </div>
            <div style="display: flex; gap: 4px;">
              <button class="action-icon edit-wishlist-btn" data-id="${item.id}" title="Sửa">✏️</button>
              <button class="action-icon delete-wishlist-btn" data-id="${item.id}" title="Xóa">🗑️</button>
            </div>
          </div>
          <div>
            <div style="display: flex; justify-content: space-between; font-size: 0.775rem; color: var(--text-muted); margin-bottom: 4px;">
              <span>Tiến độ tích lũy:</span>
              <strong style="color: ${isCompleted ? '#34d399' : '#fbbf24'};">${formatShortNumber(currentSaved)} (${pct}%)</strong>
            </div>
            <div class="wishlist-progress-track">
              <div class="wishlist-progress-fill" style="width: ${pct}%;"></div>
            </div>
          </div>
          <div class="wishlist-forecast-note">
            ${forecastText}
          </div>
        </div>
      `;
    }).join('');

    wishlistGridContainer.innerHTML = html;

    document.querySelectorAll('.edit-wishlist-btn').forEach(btn => {
      btn.addEventListener('click', (e) => editWishlistGoal(e.currentTarget.dataset.id));
    });

    document.querySelectorAll('.delete-wishlist-btn').forEach(btn => {
      btn.addEventListener('click', (e) => deleteWishlistGoal(e.currentTarget.dataset.id));
    });
  }

  const openWishlistModalBtn = document.getElementById('openWishlistModalBtn');
  const wishlistModal = document.getElementById('wishlistModal');
  const wishlistForm = document.getElementById('wishlistForm');
  const wishlistId = document.getElementById('wishlistId');
  const wishlistTitleInput = document.getElementById('wishlistTitleInput');
  const wishlistTargetInput = document.getElementById('wishlistTargetInput');
  const wishlistAllocatedInput = document.getElementById('wishlistAllocatedInput');
  const wishlistEmojiInput = document.getElementById('wishlistEmojiInput');
  const wishlistModalTitle = document.getElementById('wishlistModalTitle');
  const wishlistModalIconDisplay = document.getElementById('wishlistModalIconDisplay');
  const closeWishlistModalBtn = document.getElementById('closeWishlistModalBtn');
  const emojiPickerWrap = document.getElementById('emojiPickerWrap');

  if (emojiPickerWrap) {
    emojiPickerWrap.addEventListener('click', (e) => {
      const btn = e.target.closest('.emoji-btn');
      if (!btn) return;
      document.querySelectorAll('.emoji-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const emoji = btn.dataset.emoji || '🏠';
      if (wishlistEmojiInput) wishlistEmojiInput.value = emoji;
      if (wishlistModalIconDisplay) wishlistModalIconDisplay.textContent = emoji;
    });
  }

  if (openWishlistModalBtn) {
    openWishlistModalBtn.addEventListener('click', () => {
      resetWishlistForm();
      wishlistModal.style.display = 'flex';
    });
  }

  if (closeWishlistModalBtn) {
    closeWishlistModalBtn.addEventListener('click', () => {
      wishlistModal.style.display = 'none';
    });
  }

  function resetWishlistForm() {
    wishlistId.value = '';
    wishlistTitleInput.value = '';
    wishlistTargetInput.value = '';
    wishlistAllocatedInput.value = '0';
    wishlistEmojiInput.value = '🏠';
    if (wishlistModalTitle) wishlistModalTitle.textContent = 'Thêm Mục Tiêu Ước Mơ';
    if (wishlistModalIconDisplay) wishlistModalIconDisplay.textContent = '🏠';
    document.querySelectorAll('.emoji-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.emoji === '🏠');
    });
  }

  function editWishlistGoal(id) {
    const goal = wishlistGoals.find(g => g.id === id);
    if (!goal) return;
    wishlistId.value = goal.id;
    wishlistTitleInput.value = goal.title;
    wishlistTargetInput.value = goal.targetAmount;
    wishlistAllocatedInput.value = goal.allocatedAmount || 0;
    wishlistEmojiInput.value = goal.emoji || '🏠';
    if (wishlistModalTitle) wishlistModalTitle.textContent = 'Chỉnh Sửa Mục Tiêu';
    if (wishlistModalIconDisplay) wishlistModalIconDisplay.textContent = goal.emoji || '🏠';
    document.querySelectorAll('.emoji-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.emoji === (goal.emoji || '🏠'));
    });
    wishlistModal.style.display = 'flex';
  }

  function deleteWishlistGoal(id) {
    if (confirm('Bạn có chắc chắn muốn xóa mục tiêu này không?')) {
      wishlistGoals = wishlistGoals.filter(g => g.id !== id);
      saveWishlistGoals();
    }
  }

  if (wishlistForm) {
    wishlistForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const title = wishlistTitleInput.value.trim();
      const targetAmount = parseFloat(wishlistTargetInput.value);
      const allocatedAmount = parseFloat(wishlistAllocatedInput.value) || 0;
      const emoji = wishlistEmojiInput.value || '🏠';
      const existingId = wishlistId.value;

      if (!title || isNaN(targetAmount) || targetAmount < 100000) {
        alert('Vui lòng nhập tên mục tiêu và số tiền hợp lệ (Tối thiểu 100.000đ)!');
        return;
      }

      const newGoal = {
        id: existingId || `wishlist-${Date.now()}`,
        title: title,
        targetAmount: targetAmount,
        allocatedAmount: allocatedAmount,
        emoji: emoji
      };

      if (existingId) {
        const idx = wishlistGoals.findIndex(g => g.id === existingId);
        if (idx !== -1) wishlistGoals[idx] = newGoal;
      } else {
        wishlistGoals.push(newGoal);
      }

      saveWishlistGoals();
      wishlistModal.style.display = 'none';
    });
  }

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

  // clearAllBtn.addEventListener('click', () => {
  //   if (confirm('⚠️ CẢNH BÁO NGUY HIỂM: Bạn có chắc chắn muốn xóa TOÀN BỘ nhật ký tiết kiệm không? Hành động này không thể hoàn tác!')) {
  //     const confirmInput = prompt('Để xác nhận xóa toàn bộ dữ liệu, vui lòng gõ chữ "XÓA" vào ô dưới đây:');
  //     if (confirmInput && confirmInput.trim().toUpperCase() === 'XÓA') {
  //       entries = [];
  //       saveToStorage();
  //       refreshAll();
  //       alert('Đã xóa toàn bộ nhật ký tiết kiệm!');
  //     } else if (confirmInput !== null) {
  //       alert('Mã xác nhận không đúng. Đã hủy thao tác xóa.');
  //     }
  //   }
  // });

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

  // Auth Form Listener
  if (authForm) {
    authForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = authEmailInput.value.trim();
      const password = authPasswordInput.value.trim();

      if (!email || !password) return;
      if (!supabaseClient) {
        showAuthAlert('Chưa khởi tạo kết nối Cloud! Vui lòng làm mới trang.');
        return;
      }

      authSubmitBtn.disabled = true;
      authSubmitBtn.textContent = '⏳ Đang xử lý...';

      if (isSignUpMode) {
        // Sign Up
        const { data, error } = await supabaseClient.auth.signUp({ email, password });
        authSubmitBtn.disabled = false;
        authSubmitBtn.textContent = '✨ Đăng Ký Ngay';

        if (error) {
          showAuthAlert(error.message);
        } else if (data && data.user) {
          if (rememberMeCheckbox && rememberMeCheckbox.checked) {
            localStorage.setItem(REMEMBER_EMAIL_KEY, email);
            localStorage.setItem(REMEMBER_PASS_KEY, password);
          }
          if (data.session) {
            showAuthAlert('🎉 Tạo tài khoản và đăng nhập thành công!', false);
          } else {
            showAuthAlert('🎉 Đã tạo tài khoản! Vui lòng chuyển sang tab Đăng Nhập để vào ứng dụng.', false);
          }
        }
      } else {
        // Sign In
        const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
        authSubmitBtn.disabled = false;
        authSubmitBtn.textContent = '🔑 Đăng Nhập';

        if (error) {
          showAuthAlert('Đăng nhập thất bại: ' + (error.message === 'Invalid login credentials' ? 'Email hoặc mật khẩu không đúng!' : error.message));
        } else if (data && data.user) {
          if (rememberMeCheckbox && rememberMeCheckbox.checked) {
            localStorage.setItem(REMEMBER_EMAIL_KEY, email);
            localStorage.setItem(REMEMBER_PASS_KEY, password);
          } else {
            localStorage.removeItem(REMEMBER_EMAIL_KEY);
            localStorage.removeItem(REMEMBER_PASS_KEY);
          }
          onUserLoggedIn(data.user);
        }
      }
    });
  }

  if (toggleAuthModeBtn) {
    toggleAuthModeBtn.addEventListener('click', toggleAuthMode);
  }

  if (signOutBtn) {
    signOutBtn.addEventListener('click', async () => {
      if (confirm('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?')) {
        if (supabaseClient) await supabaseClient.auth.signOut();
        onUserLoggedOut();
      }
    });
  }

  // App Initialize
  initSupabase();
  seedInitialSampleData();
  loadWishlistGoals();
  setDefaultDate();
  entryAmount.value = formatMoneyInput(dailyGoal);
  updateEntryPreview();
  refreshAll();

  // Retry on window load for local file:/// protocol
  window.addEventListener('load', () => {
    initSupabase();
  });
})();
