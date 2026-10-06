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
  const formatCurrency = formatShortNumber;

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
  const bannerFilterPills = document.getElementById('bannerFilterPills');
  const bannerLifetimeDisplay = document.getElementById('bannerLifetimeDisplay');
  const grabMonthDisplay = document.getElementById('grabMonthDisplay');
  const grabLifetimeDisplay = document.getElementById('grabLifetimeDisplay');
  const otherMonthDisplay = document.getElementById('otherMonthDisplay');
  const otherLifetimeDisplay = document.getElementById('otherLifetimeDisplay');
  const monthCardTitle = document.getElementById('monthCardTitle');
  const yearCardTitle = document.getElementById('yearCardTitle');

  let currentBannerFilter = 'GRAB';

  function isGrabCategory(cat) {
    if (!cat) return false;
    const lower = String(cat).toLowerCase();
    return lower.includes('grab') || lower.includes('chạy xe');
  }

  if (bannerFilterPills) {
    bannerFilterPills.addEventListener('click', (e) => {
      const btn = e.target.closest('.banner-filter-pill');
      if (!btn) return;
      const filter = btn.dataset.filter;
      if (filter && filter !== currentBannerFilter) {
        currentBannerFilter = filter;
        document.querySelectorAll('.banner-filter-pill').forEach(b => b.classList.toggle('active', b.dataset.filter === filter));
        renderDashboard();
      }
    });
  }

  function calculateStreakForEntries(listEntries) {
    if (!listEntries || listEntries.length === 0) return 0;

    const dayTotals = {};
    listEntries.forEach(e => {
      if (e.date) {
        dayTotals[e.date] = (dayTotals[e.date] || 0) + (Number(e.amount) || 0);
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

    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;
    const currentDay = now.getDate();
    const currentMonthKey = `${currentYear}-${String(currentMonth).padStart(2, '0')}`;

    const selectedMonthKey = filterMonthSelect.value || currentMonthKey;
    const [selectedYear, selectedMonth] = selectedMonthKey.split('-').map(Number);
    const isCurrentMonth = (selectedMonthKey === currentMonthKey);
    const totalDaysInMonth = new Date(selectedYear, selectedMonth, 0).getDate();

    // 1. Phân loại các nguồn thu nhập
    const grabEntries = entries.filter(e => isGrabCategory(e.category || parseEntryCategory(e)));
    const otherEntries = entries.filter(e => !isGrabCategory(e.category || parseEntryCategory(e)));

    // 2. Tính số liệu cho Subtotal Breakdown Card
    const grabMonthTotal = grabEntries.filter(e => e.date && e.date.startsWith(selectedMonthKey)).reduce((s, e) => s + (Number(e.amount) || 0), 0);
    const grabLifetimeTotal = grabEntries.reduce((s, e) => s + (Number(e.amount) || 0), 0);
    const otherMonthTotal = otherEntries.filter(e => e.date && e.date.startsWith(selectedMonthKey)).reduce((s, e) => s + (Number(e.amount) || 0), 0);
    const otherLifetimeTotal = otherEntries.reduce((s, e) => s + (Number(e.amount) || 0), 0);
    const totalLifetimeSaved = entries.reduce((s, e) => s + (Number(e.amount) || 0), 0);

    if (bannerLifetimeDisplay) bannerLifetimeDisplay.textContent = formatShortNumber(totalLifetimeSaved);
    if (grabMonthDisplay) grabMonthDisplay.textContent = formatShortNumber(grabMonthTotal);
    if (grabLifetimeDisplay) grabLifetimeDisplay.textContent = formatShortNumber(grabLifetimeTotal);
    if (otherMonthDisplay) otherMonthDisplay.textContent = formatShortNumber(otherMonthTotal);
    if (otherLifetimeDisplay) otherLifetimeDisplay.textContent = formatShortNumber(otherLifetimeTotal);

    // 3. Chọn tập entries & streak theo Filter Mode đang kích hoạt
    let activeEntries = grabEntries;
    let streak = 0;
    let modeTitle = '';

    if (currentBannerFilter === 'GRAB') {
      activeEntries = grabEntries;
      streak = calculateStreakForEntries(grabEntries);
      modeTitle = isCurrentMonth
        ? `LŨY KẾ GRAB HÔM NAY (${String(currentDay).padStart(2, '0')}/${String(currentMonth).padStart(2, '0')})`
        : `TỔNG KẾT GRAB THÁNG ${selectedMonth}/${selectedYear}`;
    } else if (currentBannerFilter === 'OTHER') {
      activeEntries = otherEntries;
      streak = 0;
      modeTitle = isCurrentMonth
        ? `THU NHẬP NGUỒN KHÁC (${String(currentDay).padStart(2, '0')}/${String(currentMonth).padStart(2, '0')})`
        : `NGUỒN KHÁC THÁNG ${selectedMonth}/${selectedYear}`;
    } else {
      activeEntries = entries;
      streak = calculateStreakForEntries(entries);
      modeTitle = isCurrentMonth
        ? `TỔNG LŨY KẾ TẤT CẢ (${String(currentDay).padStart(2, '0')}/${String(currentMonth).padStart(2, '0')})`
        : `TỔNG KẾT TẤT CẢ THÁNG ${selectedMonth}/${selectedYear}`;
    }

    if (bannerTitleText) bannerTitleText.textContent = modeTitle;

    if (streakBadgeBox) {
      if (currentBannerFilter === 'OTHER') {
        streakBadgeBox.style.display = 'none';
      } else {
        streakBadgeBox.style.display = 'inline-flex';
        streakBadgeBox.textContent = `🔥 Chuỗi ${streak} ngày`;
        streakBadgeBox.className = streak >= 3 ? 'streak-badge active-streak' : 'streak-badge';
      }
    }

    // 4. Tính toán tiến độ tháng cho activeEntries
    const activeMonthEntries = activeEntries.filter(e => e.date && e.date.startsWith(selectedMonthKey));
    let monthTotalSaved = 0;
    let savedUpToToday = 0;

    activeMonthEntries.forEach(e => {
      const dayNum = parseInt(e.date.split('-')[2], 10);
      const amt = Number(e.amount) || 0;
      monthTotalSaved += amt;
      if (dayNum <= currentDay) {
        savedUpToToday += amt;
      }
    });

    const monthTarget = totalDaysInMonth * dailyGoal;
    const cumulativeTargetToToday = currentDay * dailyGoal;

    if (currentBannerFilter === 'GRAB') {
      if (isCurrentMonth) {
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
        if (bannerMetaText) bannerMetaText.innerHTML = `Tổng mục tiêu tháng: <strong>${formatShortNumber(monthTarget)}</strong>`;
        const monthDiff = monthTotalSaved - monthTarget;
        if (monthDiff >= 0) {
          statusPaceAmount.textContent = monthDiff === 0 ? 'Đạt 100% Target' : `+${formatShortNumber(monthDiff)}`;
          statusPaceAmount.className = 'banner-val text-success';
          statusPacePill.textContent = `🎉 Hoàn thành tháng! Dư +${formatShortNumber(monthDiff)}`;
        } else {
          const diffAbs = Math.abs(monthDiff);
          statusPaceAmount.textContent = `-${formatShortNumber(diffAbs)}`;
          statusPaceAmount.className = 'banner-val text-danger';
          statusPacePill.textContent = `Thiếu -${formatShortNumber(diffAbs)} so với mục tiêu tháng`;
        }
      }
    } else if (currentBannerFilter === 'OTHER') {
      statusPaceAmount.textContent = formatShortNumber(monthTotalSaved);
      statusPaceAmount.className = 'banner-val text-info';
      statusPacePill.textContent = 'Thu nhập từ Lương, Thưởng và Nguồn khác tháng này';
      if (bannerMetaText) bannerMetaText.innerHTML = `Tổng thu nhập nguồn khác toàn thời gian: <strong>${formatShortNumber(otherLifetimeTotal)}</strong>`;
    } else {
      // ALL
      if (isCurrentMonth) {
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
        if (bannerMetaText) bannerMetaText.innerHTML = `Tổng mục tiêu tháng: <strong>${formatShortNumber(monthTarget)}</strong>`;
        const monthDiff = monthTotalSaved - monthTarget;
        if (monthDiff >= 0) {
          statusPaceAmount.textContent = monthDiff === 0 ? 'Đạt 100% Target' : `+${formatShortNumber(monthDiff)}`;
          statusPaceAmount.className = 'banner-val text-success';
          statusPacePill.textContent = `🎉 Hoàn thành tháng! Dư +${formatShortNumber(monthDiff)}`;
        } else {
          const diffAbs = Math.abs(monthDiff);
          statusPaceAmount.textContent = `-${formatShortNumber(diffAbs)}`;
          statusPaceAmount.className = 'banner-val text-danger';
          statusPacePill.textContent = `Thiếu -${formatShortNumber(diffAbs)} so với mục tiêu tháng`;
        }
      }
    }

    // 5. Cập nhật 2 Mini Cards (Tiến độ tháng & Năm)
    if (monthCardTitle) {
      monthCardTitle.textContent = currentBannerFilter === 'GRAB' ? 'TIẾN ĐỘ THÁNG (GRAB)' : (currentBannerFilter === 'OTHER' ? 'TIẾN ĐỘ THÁNG (KHÁC)' : 'TIẾN ĐỘ THÁNG (TẤT CẢ)');
    }
    if (yearCardTitle) {
      yearCardTitle.textContent = currentBannerFilter === 'GRAB' ? 'TIẾN ĐỘ CẢ NĂM (GRAB)' : (currentBannerFilter === 'OTHER' ? 'TIẾN ĐỘ CẢ NĂM (KHÁC)' : 'TIẾN ĐỘ CẢ NĂM (TẤT CẢ)');
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

    // 6. Tính toán tiến độ cả năm
    const activeYearEntries = activeEntries.filter(e => e.date && e.date.startsWith(`${currentYear}`));
    let yearTotalSaved = 0;
    activeYearEntries.forEach(e => yearTotalSaved += (Number(e.amount) || 0));

    let earliestDateInYear = new Date(currentYear, 0, 1);
    if (activeYearEntries.length > 0) {
      const dates = activeYearEntries.map(e => {
        if (!e.date) return null;
        const parts = e.date.split('-');
        if (parts.length === 3) {
          return new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
        }
        return new Date(e.date);
      }).filter(d => d && !isNaN(d.getTime()));

      if (dates.length > 0) {
        const minDate = new Date(Math.min(...dates.map(d => d.getTime())));
        if (minDate.getFullYear() === currentYear) {
          earliestDateInYear = minDate;
        }
      }
    }

    const endOfYear = new Date(currentYear, 11, 31);
    const activeYearDays = Math.max(1, Math.round((endOfYear - earliestDateInYear) / (1000 * 60 * 60 * 24)) + 1);
    const yearTarget = activeYearDays * dailyGoal;

    const activeLifetimeTotal = activeEntries.reduce((s, e) => s + (Number(e.amount) || 0), 0);
    const realAvgRate = activeEntries.length === 0 ? dailyGoal : (activeLifetimeTotal / Math.max(1, activeEntries.length));
    const yearForecast = Math.round(realAvgRate * activeYearDays);

    yearSavedTotal.textContent = formatShortNumber(yearTotalSaved);
    yearForecastTotal.textContent = formatShortNumber(yearForecast);

    const yearPct = Math.min(100, Number(((yearTotalSaved / yearTarget) * 100).toFixed(1)));
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
    { id: 'w3', title: 'Quỹ dự phòng khẩn cấp', targetAmount: 10000000, allocatedAmount: 0, emoji: '🛡️' },
    { id: 'w2', title: 'Mua đất', targetAmount: 200000000, allocatedAmount: 0, emoji: '🏞️' },
    { id: 'w1', title: 'Xây nhà / Mua nhà', targetAmount: 500000000, allocatedAmount: 0, emoji: '🏠' }
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

    const sortedGoals = [...wishlistGoals].sort((a, b) => a.targetAmount - b.targetAmount);
    const html = sortedGoals.map(item => {
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
    if (typeof renderDrawerInfo === 'function') {
      renderDrawerInfo();
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

  const togglePasswordBtn = document.getElementById('togglePasswordBtn');

  if (togglePasswordBtn && authPasswordInput) {
    const showPass = () => {
      authPasswordInput.type = 'text';
      togglePasswordBtn.textContent = '👁️‍🗨️';
      togglePasswordBtn.style.opacity = '1';
    };
    const hidePass = () => {
      authPasswordInput.type = 'password';
      togglePasswordBtn.textContent = '👁️';
      togglePasswordBtn.style.opacity = '0.7';
    };

    togglePasswordBtn.addEventListener('mousedown', showPass);
    togglePasswordBtn.addEventListener('mouseup', hidePass);
    togglePasswordBtn.addEventListener('mouseleave', hidePass);

    togglePasswordBtn.addEventListener('touchstart', (e) => {
      e.preventDefault();
      showPass();
    });
    togglePasswordBtn.addEventListener('touchend', hidePass);
    togglePasswordBtn.addEventListener('touchcancel', hidePass);

    togglePasswordBtn.addEventListener('click', (e) => {
      e.preventDefault();
    });
  }

  if (signOutBtn) {
    signOutBtn.addEventListener('click', async () => {
      if (confirm('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?')) {
        if (supabaseClient) await supabaseClient.auth.signOut();
        onUserLoggedOut();
      }
    });
  }

  // =========================================================================
  // 🌙 LUNAR UTILS (HO NGOC DUC ASTRONOMICAL VIETNAMESE LUNAR ALGORITHM UTC+7)
  // =========================================================================
  const LunarUtils = {
    _can: ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'],
    _chi: ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'],

    jdFromDate: function (dd, mm, yy) {
      const a = Math.floor((14 - mm) / 12);
      const y = yy + 4800 - a;
      const m = mm + 12 * a - 3;
      return dd + Math.floor((153 * m + 2) / 5) + 365 * y + Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) - 32045;
    },

    getNewMoonDay: function (k, timeZone) {
      const T = k / 1236.85;
      const T2 = T * T;
      const T3 = T2 * T;
      const dr = Math.PI / 180.0;
      const Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
      const M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
      const Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
      const F = 21.1524 + 390.67050646 * k - 0.0016533 * T2 - 0.00000273 * T3;
      let C1 = (0.1734 - 0.000393 * T) * Math.sin(M * dr) + 0.0021 * Math.sin(2 * M * dr);
      C1 = C1 - 0.4068 * Math.sin(Mpr * dr) + 0.0161 * Math.sin(2 * Mpr * dr);
      C1 = C1 - 0.0004 * Math.sin(3 * Mpr * dr);
      C1 = C1 + 0.0104 * Math.sin(2 * F * dr) - 0.0051 * Math.sin((M + Mpr) * dr);
      C1 = C1 - 0.0074 * Math.sin((M - Mpr) * dr) + 0.0004 * Math.sin((2 * F + M) * dr);
      C1 = C1 - 0.0004 * Math.sin((2 * F - M) * dr) - 0.0006 * Math.sin((2 * F + Mpr) * dr);
      C1 = C1 + 0.0010 * Math.sin((2 * F - Mpr) * dr) + 0.0005 * Math.sin((M + 2 * Mpr) * dr);
      const deltat = (T < -0.5)
        ? 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 + 0.000000081 * T * T3
        : -0.00009 + 0.000004 * T + 0.000296 * T2 + 0.000213 * T3 + 0.000025 * T * T3;
      const JdNew = Jd1 + C1 - deltat;
      return JdNew + timeZone / 24.0;
    },

    getSunLongitude: function (jdn, timeZone) {
      const jdnUtc = jdn - 0.5 - timeZone / 24.0;
      const T = (jdnUtc - 2451545.0) / 36525.0;
      const T2 = T * T;
      const dr = Math.PI / 180.0;
      const M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
      const L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
      let DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * Math.sin(M * dr);
      DL += (0.019993 - 0.000101 * T) * Math.sin(2 * M * dr);
      DL += 0.000290 * Math.sin(3 * M * dr);
      let L = L0 + DL;
      L = L * dr;
      L = L - 2 * Math.PI * Math.floor(L / (2 * Math.PI));
      return Math.floor(L / dr / 30.0) * 1.0;
    },

    getLunarMonth11: function (yy, timeZone) {
      const off = this.jdFromDate(31, 12, yy) - 2415021;
      const k = Math.floor(off / 29.53058868);
      let nm = this.getNewMoonDay(k, timeZone);
      const sunLong = this.getSunLongitude(nm, timeZone);
      if (sunLong >= 9) {
        nm = this.getNewMoonDay(k - 1, timeZone);
      }
      return Math.floor(nm + 0.5);
    },

    convertSolarToLunar: function (dd, mm, yy, timeZone = 7.0) {
      const dayNumber = this.jdFromDate(dd, mm, yy);
      let k = Math.floor((dayNumber - 2415021.07699) / 29.53058868);
      const nextMonthStart = Math.floor(this.getNewMoonDay(k + 1, timeZone) + 0.5);
      if (nextMonthStart <= dayNumber) {
        k = k + 1;
      }
      let lastMonthStart = Math.floor(this.getNewMoonDay(k, timeZone) + 0.5);
      if (lastMonthStart > dayNumber) {
        k = k - 1;
        lastMonthStart = Math.floor(this.getNewMoonDay(k, timeZone) + 0.5);
      }
      const lunarDay = dayNumber - lastMonthStart + 1;
      let a11 = this.getLunarMonth11(yy, timeZone);
      let b11 = a11;

      if (dayNumber >= a11) {
        b11 = this.getLunarMonth11(yy + 1, timeZone);
      } else {
        a11 = this.getLunarMonth11(yy - 1, timeZone);
      }

      const kCurrent = Math.round((lastMonthStart - 2415021.07699) / 29.53058868);
      const kA11 = Math.round((a11 - 2415021.07699) / 29.53058868);
      const kB11 = Math.round((b11 - 2415021.07699) / 29.53058868);

      let lunarMonth = kCurrent - kA11 + 11;
      if (kB11 - kA11 === 13) {
        const leapMonthDiff = kCurrent - kA11;
        let leapPos = 0;
        for (let i = 0; i < 13; i++) {
          const nm1 = Math.floor(this.getNewMoonDay(kA11 + i, timeZone) + 0.5);
          const nm2 = Math.floor(this.getNewMoonDay(kA11 + i + 1, timeZone) + 0.5);
          const sl1 = this.getSunLongitude(nm1 * 1.0, timeZone);
          const sl2 = this.getSunLongitude(nm2 * 1.0, timeZone);
          if (sl1 === sl2) {
            leapPos = i;
            break;
          }
        }
        if (leapPos > 0 && leapMonthDiff > leapPos) {
          lunarMonth = lunarMonth - 1;
        }
      }

      if (lunarMonth > 12) lunarMonth = lunarMonth - 12;
      if (lunarMonth < 1) lunarMonth = lunarMonth + 12;

      let finalYear = (dayNumber >= a11) ? (lunarMonth >= 11 ? yy : yy + 1) : (lunarMonth >= 11 ? yy - 1 : yy);
      if (mm <= 2 && lunarMonth >= 10) finalYear = yy - 1;
      if (mm >= 11 && lunarMonth <= 2) finalYear = yy;

      return [lunarDay, lunarMonth, finalYear];
    },

    getCanChiDay: function (date) {
      const jd = this.jdFromDate(date.getDate(), date.getMonth() + 1, date.getFullYear());
      const canIdx = (jd + 9) % 10;
      const chiIdx = (jd + 1) % 12;
      return `${this._can[canIdx]} ${this._chi[chiIdx]}`;
    },

    getCanChiYear: function (year) {
      const canIdx = (year - 4) % 10;
      const chiIdx = (year - 4) % 12;
      return `${this._can[canIdx < 0 ? canIdx + 10 : canIdx]} ${this._chi[chiIdx < 0 ? chiIdx + 12 : chiIdx]}`;
    },

    getNextTetSolarDate: function (now) {
      for (let i = 0; i <= 400; i++) {
        const candidate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i);
        const lunar = this.convertSolarToLunar(candidate.getDate(), candidate.getMonth() + 1, candidate.getFullYear());
        if (lunar[0] === 1 && lunar[1] === 1) {
          return candidate;
        }
      }
      return new Date(now.getFullYear() + 1, 1, 6); // Fallback
    }
  };

  // =========================================================================
  // 📱 NAVIGATION MENU DRAWER & TET WIDGET CONTROLLER
  // =========================================================================
  const openMenuDrawerBtn = document.getElementById('openMenuDrawerBtn');
  const drawerOverlay = document.getElementById('drawerOverlay');
  const closeDrawerBtn = document.getElementById('closeDrawerBtn');
  const drawerSignOutBtn = document.getElementById('drawerSignOutBtn');
  const drawerUserEmail = document.getElementById('drawerUserEmail');

  const tetCanChiYearDisplay = document.getElementById('tetCanChiYearDisplay');
  const tetMung1DateDisplay = document.getElementById('tetMung1DateDisplay');
  const tetDaysLeftDisplay = document.getElementById('tetDaysLeftDisplay');
  const tetEstimatedFundDisplay = document.getElementById('tetEstimatedFundDisplay');

  const lunarSolarToday = document.getElementById('lunarSolarToday');
  const lunarCanChiDayDisplay = document.getElementById('lunarCanChiDayDisplay');
  const lunarDayNumDisplay = document.getElementById('lunarDayNumDisplay');
  const lunarMonthNameDisplay = document.getElementById('lunarMonthNameDisplay');
  const lunarYearCanChiDisplay = document.getElementById('lunarYearCanChiDisplay');
  const lunarSpecialBadge = document.getElementById('lunarSpecialBadge');

  const drawerChangeGoalBtn = document.getElementById('drawerChangeGoalBtn');
  const drawerGoalSub = document.getElementById('drawerGoalSub');
  const drawerExpenseBtn = document.getElementById('drawerExpenseBtn');
  const drawerWeeklyReportBtn = document.getElementById('drawerWeeklyReportBtn');
  const drawerCalendarBtn = document.getElementById('drawerCalendarBtn');
  const drawerCompoundInterestBtn = document.getElementById('drawerCompoundInterestBtn');
  const drawerAiPredictorBtn = document.getElementById('drawerAiPredictorBtn');

  function renderDrawerInfo() {
    const now = new Date();
    const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Update Email
    if (drawerUserEmail) {
      drawerUserEmail.textContent = currentUser ? currentUser.email : 'user@gmail.com';
    }

    if (drawerGoalSub) {
      drawerGoalSub.textContent = `Thay đổi số tiền mục tiêu ${formatCurrency(dailyGoal)}/ngày`;
    }

    // Lunar Today Calculation
    const lunarList = LunarUtils.convertSolarToLunar(now.getDate(), now.getMonth() + 1, now.getFullYear());
    const lDay = lunarList[0];
    const lMonth = lunarList[1];
    const lYear = lunarList[2];
    const canChiDay = LunarUtils.getCanChiDay(now);
    const canChiYear = LunarUtils.getCanChiYear(lYear);

    if (lunarSolarToday) lunarSolarToday.textContent = `${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}`;
    if (lunarCanChiDayDisplay) lunarCanChiDayDisplay.textContent = `Ngày ${canChiDay}`;
    if (lunarDayNumDisplay) lunarDayNumDisplay.textContent = lDay;
    if (lunarMonthNameDisplay) lunarMonthNameDisplay.textContent = `Tháng ${lMonth} Âm`;
    if (lunarYearCanChiDisplay) lunarYearCanChiDisplay.textContent = canChiYear;

    if (lunarSpecialBadge) {
      if (lDay === 1) {
        lunarSpecialBadge.textContent = '🌙 Mùng 1 May Mắn';
        lunarSpecialBadge.style.display = 'inline-block';
      } else if (lDay === 15) {
        lunarSpecialBadge.textContent = '🌕 Ngày Rằm 15';
        lunarSpecialBadge.style.display = 'inline-block';
      } else {
        lunarSpecialBadge.style.display = 'none';
      }
    }

    // Tet Countdown Calculation (aligned with Mobile: Grab Lifetime + DaysLeft * GrabRate)
    const nextTet = LunarUtils.getNextTetSolarDate(todayMidnight);
    const msDiff = nextTet.getTime() - todayMidnight.getTime();
    const daysLeftToTet = Math.max(0, Math.round(msDiff / (1000 * 60 * 60 * 24)));

    const tetLunarList = LunarUtils.convertSolarToLunar(nextTet.getDate(), nextTet.getMonth() + 1, nextTet.getFullYear());
    const tetYearCanChi = LunarUtils.getCanChiYear(tetLunarList[2]);

    const grabEntries = entries.filter(e => isGrabCategory(e.category));
    let grabTotal = 0;
    grabEntries.forEach(e => grabTotal += (e.amount || 0));
    const grabRate = grabEntries.length === 0 ? dailyGoal : (grabTotal / grabEntries.length);
    const estTetFund = grabTotal + (daysLeftToTet * grabRate);

    if (tetCanChiYearDisplay) tetCanChiYearDisplay.textContent = tetYearCanChi;
    if (tetMung1DateDisplay) tetMung1DateDisplay.textContent = `Mùng 1: ${nextTet.getDate()}/${nextTet.getMonth() + 1}`;
    if (tetDaysLeftDisplay) tetDaysLeftDisplay.textContent = daysLeftToTet;
    if (tetEstimatedFundDisplay) tetEstimatedFundDisplay.textContent = formatCurrency(Math.round(estTetFund));
  }

  function openDrawer() {
    try {
      renderDrawerInfo();
    } catch (err) {
      console.error('Error in renderDrawerInfo:', err);
    }
    const overlay = document.getElementById('drawerOverlay');
    if (overlay) {
      overlay.style.display = 'flex';
      overlay.style.visibility = 'visible';
      overlay.style.opacity = '1';
    }
  }

  function closeDrawer() {
    const overlay = document.getElementById('drawerOverlay');
    if (overlay) overlay.style.display = 'none';
  }

  if (openMenuDrawerBtn) {
    openMenuDrawerBtn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      openDrawer();
    });
  }
  if (closeDrawerBtn) closeDrawerBtn.addEventListener('click', closeDrawer);
  const currentDrawerOverlay = document.getElementById('drawerOverlay');
  if (currentDrawerOverlay) {
    currentDrawerOverlay.addEventListener('click', (e) => {
      if (e.target === currentDrawerOverlay) closeDrawer();
    });
  }

  if (drawerSignOutBtn) {
    drawerSignOutBtn.addEventListener('click', async () => {
      closeDrawer();
      if (confirm('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?')) {
        if (supabaseClient) await supabaseClient.auth.signOut();
        onUserLoggedOut();
      }
    });
  }

  if (drawerChangeGoalBtn) {
    drawerChangeGoalBtn.addEventListener('click', () => {
      closeDrawer();
      modalGoalInput.value = dailyGoal;
      goalModal.style.display = 'flex';
    });
  }

  // =========================================================================
  // 🧾 SỔ GHI CHI TIÊU HẰNG NGÀY (EXPENSE TRACKER)
  // =========================================================================
  const EXPENSES_STORAGE_KEY = 'savings_tracker_expenses_v1';
  let expensesList = JSON.parse(localStorage.getItem(EXPENSES_STORAGE_KEY)) || [];

  const expenseModal = document.getElementById('expenseModal');
  const closeExpenseModalBtn = document.getElementById('closeExpenseModalBtn');
  const expenseForm = document.getElementById('expenseForm');
  const expenseDateInput = document.getElementById('expenseDate');
  const expenseCategorySelect = document.getElementById('expenseCategory');
  const expenseAmountInput = document.getElementById('expenseAmount');
  const expenseNoteInput = document.getElementById('expenseNote');
  const expenseMonthTotalText = document.getElementById('expenseMonthTotalText');
  const expenseTableBody = document.getElementById('expenseTableBody');

  function saveExpensesToStorage() {
    localStorage.setItem(EXPENSES_STORAGE_KEY, JSON.stringify(expensesList));
  }

  async function syncSaveExpenseToCloud(item) {
    if (!supabaseClient || !currentUser) return;
    try {
      await supabaseClient.from('expenses').upsert({
        id: item.id,
        user_id: currentUser.id,
        entry_date: item.date,
        amount: Math.round(item.amount),
        category: item.category,
        note: item.note || ''
      });
    } catch (e) {
      console.warn('Expense sync error:', e);
    }
  }

  async function syncDeleteExpenseFromCloud(id) {
    if (!supabaseClient) return;
    try {
      await supabaseClient.from('expenses').delete().eq('id', id);
    } catch (e) {
      console.warn('Expense delete error:', e);
    }
  }

  async function fetchExpensesFromCloud() {
    if (!supabaseClient || !currentUser) return;
    try {
      const { data, error } = await supabaseClient.from('expenses')
        .select('*')
        .eq('user_id', currentUser.id)
        .order('entry_date', { ascending: false });
      if (!error && data && data.length > 0) {
        expensesList = data.map(d => ({
          id: d.id,
          date: d.entry_date || d.date,
          amount: parseFloat(d.amount) || 0,
          category: d.category || 'Khác',
          note: d.note || ''
        }));
        saveExpensesToStorage();
        renderExpenses();
      }
    } catch (e) {
      console.warn('Fetch cloud expenses error:', e);
    }
  }

  function renderExpenses() {
    if (!expenseTableBody) return;
    const now = new Date();
    const currentMonthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    let monthTotal = 0;

    const sorted = [...expensesList].sort((a, b) => b.date.localeCompare(a.date));
    expenseTableBody.innerHTML = '';

    if (sorted.length === 0) {
      expenseTableBody.innerHTML = '<tr><td colspan="5" class="text-center" style="padding: 16px; color: var(--text-muted);">Chưa có khoản chi nào được ghi nhận.</td></tr>';
      if (expenseMonthTotalText) expenseMonthTotalText.textContent = '0 đ';
      return;
    }

    sorted.forEach(item => {
      if (item.date && item.date.startsWith(currentMonthKey)) {
        monthTotal += (item.amount || 0);
      }
      const tr = document.createElement('tr');
      const dateParts = (item.date || '').split('-');
      const formattedDate = dateParts.length === 3 ? `${dateParts[2]}/${dateParts[1]}/${dateParts[0]}` : item.date;

      tr.innerHTML = `
        <td style="white-space: nowrap; font-size: 0.8rem;">${formattedDate}</td>
        <td style="font-size: 0.8rem; font-weight: 600;">${item.category || 'Khác'}</td>
        <td style="font-weight: 800; color: #f87171; white-space: nowrap;">${formatCurrency(item.amount)}</td>
        <td style="font-size: 0.8rem; color: var(--text-muted);">${item.note || '-'}</td>
        <td class="text-right"><button class="btn-text-danger-sm delete-expense-btn" data-id="${item.id}">✕</button></td>
      `;
      expenseTableBody.appendChild(tr);
    });

    if (expenseMonthTotalText) expenseMonthTotalText.textContent = formatCurrency(monthTotal);

    // Wire delete buttons
    document.querySelectorAll('.delete-expense-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        deleteExpense(id);
      });
    });
  }

  function deleteExpense(id) {
    if (confirm('Bạn có chắc muốn xóa khoản chi này?')) {
      expensesList = expensesList.filter(e => e.id !== id);
      saveExpensesToStorage();
      syncDeleteExpenseFromCloud(id);
      renderExpenses();
    }
  }

  if (expenseAmountInput) {
    expenseAmountInput.addEventListener('input', (e) => {
      const raw = e.target.value.replace(/\D/g, '');
      e.target.value = raw ? formatMoneyInput(parseInt(raw, 10)) : '';
    });
  }

  if (expenseForm) {
    expenseForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const rawAmount = parseMoney(expenseAmountInput.value);
      if (isNaN(rawAmount) || rawAmount <= 0) {
        alert('Vui lòng nhập số tiền chi tiêu hợp lệ!');
        return;
      }
      const newExp = {
        id: `exp-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`,
        date: expenseDateInput.value || getTodayDateString(),
        amount: rawAmount,
        category: expenseCategorySelect.value,
        note: expenseNoteInput.value.trim()
      };
      expensesList.unshift(newExp);
      saveExpensesToStorage();
      syncSaveExpenseToCloud(newExp);
      expenseAmountInput.value = '';
      expenseNoteInput.value = '';
      renderExpenses();
    });
  }

  if (drawerExpenseBtn) {
    drawerExpenseBtn.addEventListener('click', () => {
      closeDrawer();
      if (expenseDateInput) expenseDateInput.value = getTodayDateString();
      renderExpenses();
      if (expenseModal) expenseModal.style.display = 'flex';
      fetchExpensesFromCloud();
    });
  }

  if (closeExpenseModalBtn) {
    closeExpenseModalBtn.addEventListener('click', () => {
      if (expenseModal) expenseModal.style.display = 'none';
    });
  }

  // =========================================================================
  // 📊 BÁO CÁO TỔNG KẾT TUẦN (WEEKLY REPORT)
  // =========================================================================
  const weeklyReportModal = document.getElementById('weeklyReportModal');
  const closeWeeklyReportModalBtn = document.getElementById('closeWeeklyReportModalBtn');
  const weeklyReportContent = document.getElementById('weeklyReportContent');

  function renderWeeklyReport() {
    if (!weeklyReportContent) return;
    const weeklyGoal = dailyGoal * 7;
    const now = new Date();
    const dayOfWeek = (now.getDay() === 0) ? 7 : now.getDay(); // 1=Mon, 7=Sun
    const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (dayOfWeek - 1));

    let weeklyTotal = 0;
    let savedDaysCount = 0;
    const daysData = [];

    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    for (let i = 0; i < 7; i++) {
      const d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      const dStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      const dayEntries = entries.filter(e => e.date === dStr && isGrabCategory(e.category));
      let dayAmount = 0;
      dayEntries.forEach(e => dayAmount += (e.amount || 0));

      weeklyTotal += dayAmount;
      if (dayAmount >= dailyGoal) savedDaysCount++;

      daysData.push({
        label: dayLabels[i],
        amount: dayAmount,
        isSaved: dayAmount >= dailyGoal,
        hasPartial: dayAmount > 0 && dayAmount < dailyGoal,
        dateStr: `${d.getDate()}/${d.getMonth() + 1}`
      });
    }

    const completionPercent = weeklyGoal > 0 ? Math.min(999, Math.round((weeklyTotal / weeklyGoal) * 100)) : 0;

    let badgeEmoji = '🏆';
    let badgeTitle = 'XUẤT SẮC TÍCH LŨY!';
    let motivationQuote = 'Bạn đang duy trì thói quen quản lý tài chính cực kỳ kỷ luật!';
    let accentColor = '#10b981';

    if (completionPercent >= 100) {
      badgeEmoji = '👑';
      badgeTitle = 'BẬC THẦY TIẾT KIỆM TUẦN!';
      motivationQuote = 'Chúc mừng bạn đã hoàn thành 100% mục tiêu tiết kiệm tuần này!';
      accentColor = '#fbbf24';
    } else if (completionPercent >= 70) {
      badgeEmoji = '🔥';
      badgeTitle = 'GIỮ VỮNG PHONG ĐỘ!';
      motivationQuote = 'Bạn đã đạt hơn 70% target tuần. Hãy tiếp tục phát huy nhé!';
      accentColor = '#38bdf8';
    } else {
      badgeEmoji = '💪';
      badgeTitle = 'CỐ LÊN BẠN ƠI!';
      motivationQuote = 'Mỗi đồng tiết kiệm hôm nay là sự chuẩn bị vững chắc cho tương lai!';
      accentColor = '#f59e0b';
    }

    weeklyReportContent.innerHTML = `
      <div style="text-align: center; margin-bottom: 14px;">
        <div style="display: inline-block; padding: 4px 12px; border-radius: 20px; background: rgba(255,255,255,0.08); border: 1px solid ${accentColor}; color: ${accentColor}; font-weight: 800; font-size: 0.85rem;">
          ${badgeEmoji} ${badgeTitle}
        </div>
      </div>

      <div style="background: rgba(15, 23, 42, 0.6); border: 1px solid var(--border-color); border-radius: 14px; padding: 14px; text-align: center; margin-bottom: 14px;">
        <div style="font-size: 0.75rem; color: var(--text-muted); font-weight: 700;">TỔNG TÍCH LŨY TUẦN NÀY (GRAB)</div>
        <div style="font-size: 1.8rem; font-weight: 900; color: #10b981; margin: 4px 0;">${formatCurrency(weeklyTotal)}</div>
        <div class="progress-bar-wrap" style="height: 10px; margin: 8px 0;">
          <div class="progress-bar-fill" style="width: ${Math.min(100, completionPercent)}%; background: ${accentColor};"></div>
        </div>
        <div style="display: flex; justify-content: space-between; font-size: 0.75rem; color: var(--text-muted);">
          <span>Target Tuần: ${formatCurrency(weeklyGoal)}</span>
          <span style="font-weight: 800; color: ${accentColor};">${completionPercent}% Đạt Target</span>
        </div>
      </div>

      <div style="background: rgba(15, 23, 42, 0.6); border: 1px solid var(--border-color); border-radius: 14px; padding: 12px; margin-bottom: 14px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
          <span style="font-size: 0.775rem; font-weight: 700; color: var(--text-main);">Chuỗi 7 Ngày Trong Tuần</span>
          <span style="font-size: 0.7rem; font-weight: 700; color: #10b981; background: rgba(16, 185, 129, 0.15); padding: 2px 8px; border-radius: 10px;">${savedDaysCount}/7 Ngày</span>
        </div>
        <div style="display: flex; justify-content: space-between; text-align: center;">
          ${daysData.map(d => {
            let icon = '⚪';
            let color = 'var(--text-muted)';
            if (d.isSaved) { icon = '🟢'; color = '#10b981'; }
            else if (d.hasPartial) { icon = '🟡'; color = '#38bdf8'; }
            return `
              <div style="flex: 1;">
                <div style="font-size: 0.75rem; font-weight: 800; color: ${d.label === 'CN' ? '#f87171' : 'var(--text-muted)'};">${d.label}</div>
                <div style="font-size: 1.1rem; margin: 4px 0;">${icon}</div>
                <div style="font-size: 0.65rem; color: ${color}; font-weight: 600;">${d.dateStr}</div>
              </div>
            `;
          }).join('')}
        </div>
      </div>

      <div style="background: rgba(251, 191, 36, 0.08); border: 1px solid rgba(251, 191, 36, 0.25); border-radius: 12px; padding: 10px 12px; font-size: 0.775rem; color: #fef08a; text-align: center;">
        💬 "${motivationQuote}"
      </div>
    `;
  }

  if (drawerWeeklyReportBtn) {
    drawerWeeklyReportBtn.addEventListener('click', () => {
      closeDrawer();
      renderWeeklyReport();
      if (weeklyReportModal) weeklyReportModal.style.display = 'flex';
    });
  }

  if (closeWeeklyReportModalBtn) {
    closeWeeklyReportModalBtn.addEventListener('click', () => {
      if (weeklyReportModal) weeklyReportModal.style.display = 'none';
    });
  }

  // =========================================================================
  // 📅 LỊCH VẠN NIÊN & ÂM LỊCH (PERPETUAL CALENDAR)
  // =========================================================================
  const calendarModal = document.getElementById('calendarModal');
  const closeCalendarModalBtn = document.getElementById('closeCalendarModalBtn');
  const calendarModalContent = document.getElementById('calendarModalContent');
  let calSelectedDate = new Date();
  let calViewMonth = new Date(calSelectedDate.getFullYear(), calSelectedDate.getMonth(), 1);

  function renderCalendar() {
    if (!calendarModalContent) return;
    const now = new Date();
    const sel = calSelectedDate;
    const viewY = calViewMonth.getFullYear();
    const viewM = calViewMonth.getMonth();

    const isToday = (sel.getFullYear() === now.getFullYear() && sel.getMonth() === now.getMonth() && sel.getDate() === now.getDate());

    const lunarList = LunarUtils.convertSolarToLunar(sel.getDate(), sel.getMonth() + 1, sel.getFullYear());
    const lDay = lunarList[0];
    const lMonth = lunarList[1];
    const lYear = lunarList[2];
    const canChiDayStr = LunarUtils.getCanChiDay(sel);
    const canChiYearStr = LunarUtils.getCanChiYear(lYear);

    const isMung1OrRam = (lDay === 1 || lDay === 15);
    const dayNames = ['CHỦ NHẬT', 'THỨ HAI', 'THỨ BA', 'THỨ TƯ', 'THỨ NĂM', 'THỨ SÁU', 'THỨ BẢY'];
    const dayOfWeekStr = dayNames[sel.getDay()];

    let specialBadge = '';
    if (lDay === 1) specialBadge = '🌙 MÙNG 1 ÂM LỊCH • KHỞI ĐẦU MAY MẮN';
    else if (lDay === 15) specialBadge = '🌕 NGÀY RẰM 15 ÂM LỊCH • NĂNG LƯỢNG AN LẠC';

    const daysInMonth = new Date(viewY, viewM + 1, 0).getDate();
    const firstDayIndex = new Date(viewY, viewM, 1).getDay(); // 0=Sun, 1=Mon...
    const leadingPadding = (firstDayIndex === 0) ? 6 : (firstDayIndex - 1); // Align Mon=0

    let gridHtml = '';
    for (let p = 0; p < leadingPadding; p++) {
      gridHtml += '<div style="aspect-ratio: 1; opacity: 0;"></div>';
    }

    for (let d = 1; d <= daysInMonth; d++) {
      const cellDate = new Date(viewY, viewM, d);
      const isCellSel = (cellDate.getFullYear() === sel.getFullYear() && cellDate.getMonth() === sel.getMonth() && cellDate.getDate() === sel.getDate());
      const isCellToday = (cellDate.getFullYear() === now.getFullYear() && cellDate.getMonth() === now.getMonth() && cellDate.getDate() === now.getDate());

      const cLunar = LunarUtils.convertSolarToLunar(d, viewM + 1, viewY);
      const cLDay = cLunar[0];
      const cLMonth = cLunar[1];
      const cIsMung1OrRam = (cLDay === 1 || cLDay === 15);

      let bg = 'rgba(15, 23, 42, 0.5)';
      let border = '1px solid var(--border-color)';
      let color = 'var(--text-main)';

      if (isCellSel) {
        bg = '#38bdf8';
        border = '1.5px solid #38bdf8';
        color = '#000000';
      } else if (isCellToday) {
        bg = 'rgba(56, 189, 248, 0.2)';
        border = '1.5px solid #38bdf8';
      } else if (cIsMung1OrRam) {
        bg = 'rgba(251, 191, 36, 0.15)';
        border = '1px solid #fbbf24';
      }

      gridHtml += `
        <div class="cal-cell" data-day="${d}" style="aspect-ratio: 1; border-radius: 8px; background: ${bg}; border: ${border}; display: flex; flex-direction: column; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s ease;">
          <span style="font-size: 0.85rem; font-weight: 800; color: ${isCellSel ? '#000' : (cellDate.getDay() === 0 ? '#f87171' : color)}; line-height: 1;">${d}</span>
          <span style="font-size: 0.625rem; font-weight: 700; color: ${isCellSel ? '#1e293b' : (cIsMung1OrRam ? '#fbbf24' : 'var(--text-muted)')}; margin-top: 2px;">${cLDay === 1 ? `1/${cLMonth}` : cLDay}</span>
        </div>
      `;
    }

    calendarModalContent.innerHTML = `
      <!-- DUAL DESK CALENDAR BLOCK -->
      <div style="background: rgba(15, 23, 42, 0.8); border: 1.5px solid ${isMung1OrRam ? '#fbbf24' : (isToday ? '#38bdf8' : 'var(--border-color)')}; border-radius: 16px; overflow: hidden; margin-bottom: 12px;">
        <div style="background: rgba(0, 0, 0, 0.4); padding: 8px 14px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color);">
          <span style="font-size: 0.7rem; font-weight: 800; color: #fbbf24; letter-spacing: 0.05em;">THÁNG ${lMonth} ÂM LỊCH • NĂM ${canChiYearStr}</span>
          <span style="font-size: 0.65rem; color: var(--text-muted);">Hoàng Đạo</span>
        </div>
        <div style="display: flex; padding: 14px; align-items: center; text-align: center;">
          <!-- SOLAR LEFT -->
          <div style="flex: 1;">
            <div style="display: inline-block; font-size: 0.65rem; font-weight: 700; color: #38bdf8; background: rgba(56, 189, 248, 0.15); padding: 2px 6px; border-radius: 6px; margin-bottom: 4px;">☀️ DƯƠNG LỊCH</div>
            <div style="font-size: 2.8rem; font-weight: 900; line-height: 1; color: var(--text-main);">${sel.getDate()}</div>
            <div style="font-size: 0.775rem; font-weight: 800; color: ${sel.getDay() === 0 ? '#f87171' : '#38bdf8'}; margin-top: 4px;">${dayOfWeekStr}</div>
            <div style="font-size: 0.7rem; color: var(--text-muted);">Tháng ${sel.getMonth() + 1}/${sel.getFullYear()}</div>
          </div>
          <!-- DIVIDER -->
          <div style="width: 1px; height: 75px; background: var(--border-color); margin: 0 8px;"></div>
          <!-- LUNAR RIGHT -->
          <div style="flex: 1;">
            <div style="display: inline-block; font-size: 0.65rem; font-weight: 700; color: #fbbf24; background: rgba(251, 191, 36, 0.15); padding: 2px 6px; border-radius: 6px; margin-bottom: 4px;">🌙 ÂM LỊCH</div>
            <div style="font-size: 2.8rem; font-weight: 900; line-height: 1; color: #fbbf24;">${lDay}</div>
            <div style="font-size: 0.775rem; font-weight: 800; color: #fbbf24; margin-top: 4px;">Ngày ${canChiDayStr}</div>
            <div style="font-size: 0.7rem; color: var(--text-muted);">Tháng ${lMonth} Âm Lịch</div>
          </div>
        </div>
      </div>

      ${specialBadge ? `
        <div style="background: rgba(251, 191, 36, 0.12); border: 1px solid #fbbf24; border-radius: 10px; padding: 6px 10px; text-align: center; color: #fbbf24; font-size: 0.75rem; font-weight: 800; margin-bottom: 12px;">
          ${specialBadge}
        </div>
      ` : ''}

      <!-- MONTH GRID HEADER -->
      <div style="display: flex; justify-content: space-between; align-items: center; background: rgba(15, 23, 42, 0.6); border: 1px solid var(--border-color); border-radius: 10px; padding: 6px 12px; margin-bottom: 8px;">
        <button id="calPrevMonthBtn" class="btn-ghost" style="padding: 4px 10px; font-size: 0.9rem;">◀</button>
        <span style="font-size: 0.825rem; font-weight: 800; color: var(--text-main);">THÁNG ${viewM + 1}/${viewY}</span>
        <button id="calNextMonthBtn" class="btn-ghost" style="padding: 4px 10px; font-size: 0.9rem;">▶</button>
      </div>

      <!-- WEEKDAY HEADER -->
      <div style="display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; text-align: center; font-size: 0.7rem; font-weight: 800; color: var(--text-muted); margin-bottom: 6px;">
        <div>T2</div><div>T3</div><div>T4</div><div>T5</div><div>T6</div><div>T7</div><div style="color: #f87171;">CN</div>
      </div>

      <!-- GRID BODY -->
      <div style="display: grid; grid-template-columns: repeat(7, 1fr); gap: 5px;">
        ${gridHtml}
      </div>
    `;

    // Month nav buttons
    document.getElementById('calPrevMonthBtn').addEventListener('click', () => {
      calViewMonth = new Date(calViewMonth.getFullYear(), calViewMonth.getMonth() - 1, 1);
      renderCalendar();
    });
    document.getElementById('calNextMonthBtn').addEventListener('click', () => {
      calViewMonth = new Date(calViewMonth.getFullYear(), calViewMonth.getMonth() + 1, 1);
      renderCalendar();
    });

    // Cell clicks
    calendarModalContent.querySelectorAll('.cal-cell').forEach(cell => {
      cell.addEventListener('click', () => {
        const d = parseInt(cell.getAttribute('data-day'), 10);
        calSelectedDate = new Date(calViewMonth.getFullYear(), calViewMonth.getMonth(), d);
        renderCalendar();
      });
    });
  }

  if (drawerCalendarBtn) {
    drawerCalendarBtn.addEventListener('click', () => {
      closeDrawer();
      calSelectedDate = new Date();
      calViewMonth = new Date(calSelectedDate.getFullYear(), calSelectedDate.getMonth(), 1);
      renderCalendar();
      if (calendarModal) calendarModal.style.display = 'flex';
    });
  }

  if (closeCalendarModalBtn) {
    closeCalendarModalBtn.addEventListener('click', () => {
      if (calendarModal) calendarModal.style.display = 'none';
    });
  }

  // =========================================================================
  // 🧮 MÁY TÍNH LÃI KÉP & DỰ BÁO (COMPOUND INTEREST CALCULATOR)
  // =========================================================================
  const compoundInterestModal = document.getElementById('compoundInterestModal');
  const closeCompoundInterestModalBtn = document.getElementById('closeCompoundInterestModalBtn');
  const ciDailyDeposit = document.getElementById('ciDailyDeposit');
  const ciRate = document.getElementById('ciRate');
  const ciYears = document.getElementById('ciYears');
  const ciResultBox = document.getElementById('ciResultBox');

  function calculateCompoundInterest() {
    if (!ciResultBox) return;
    const dailyDep = parseFloat(ciDailyDeposit.value) || dailyGoal;
    const rate = (parseFloat(ciRate.value) || 6.0) / 100;
    const years = parseInt(ciYears.value, 10) || 3;

    const yearlyDeposit = dailyDep * 365;
    let total = 0;
    for (let i = 0; i < years; i++) {
      total = (total + yearlyDeposit) * (1 + rate);
    }

    const rawSavings = dailyDep * 365 * years;
    const interestGained = Math.max(0, total - rawSavings);

    ciResultBox.innerHTML = `
      <div style="font-size: 0.75rem; color: var(--text-muted); font-weight: 700; margin-bottom: 4px;">DỰ BÁO TÀI SẢN SAU ${years} NĂM TÍCH LŨY:</div>
      <div style="font-size: 1.6rem; font-weight: 900; color: #10b981; margin-bottom: 8px;">${formatCurrency(Math.round(total))}</div>
      <div style="display: flex; justify-content: space-between; font-size: 0.775rem; padding: 4px 0; border-top: 1px solid rgba(255,255,255,0.1);">
        <span style="color: var(--text-muted);">Tiền gốc đóng vào:</span>
        <strong style="color: var(--text-main);">${formatCurrency(Math.round(rawSavings))}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; font-size: 0.775rem; padding: 4px 0;">
        <span style="color: var(--text-muted);">Tiền lãi sinh lời (+${(rate * 100).toFixed(1)}%):</span>
        <strong style="color: #fbbf24;">+${formatCurrency(Math.round(interestGained))}</strong>
      </div>
    `;
  }

  if (ciDailyDeposit) ciDailyDeposit.addEventListener('input', calculateCompoundInterest);
  if (ciRate) ciRate.addEventListener('input', calculateCompoundInterest);
  if (ciYears) ciYears.addEventListener('change', calculateCompoundInterest);

  if (drawerCompoundInterestBtn) {
    drawerCompoundInterestBtn.addEventListener('click', () => {
      closeDrawer();
      if (ciDailyDeposit) ciDailyDeposit.value = dailyGoal;
      calculateCompoundInterest();
      if (compoundInterestModal) compoundInterestModal.style.display = 'flex';
    });
  }

  if (closeCompoundInterestModalBtn) {
    closeCompoundInterestModalBtn.addEventListener('click', () => {
      if (compoundInterestModal) compoundInterestModal.style.display = 'none';
    });
  }

  // =========================================================================
  // 🔮 AI DỰ BÁO CHẠM MỐC TÀI CHÍNH (AI WEALTH PREDICTOR)
  // =========================================================================
  const aiPredictorModal = document.getElementById('aiPredictorModal');
  const closeAiPredictorModalBtn = document.getElementById('closeAiPredictorModalBtn');
  const aiPredictorContent = document.getElementById('aiPredictorContent');

  function renderAiPredictor() {
    if (!aiPredictorContent) return;
    const now = new Date();
    const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    let totalLifetime = 0;
    entries.forEach(e => totalLifetime += (e.amount || 0));

    const dailyRate = entries.length === 0 ? dailyGoal : (totalLifetime / entries.length);

    const calcEstDate = (target) => {
      if (totalLifetime >= target) return now;
      const remaining = target - totalLifetime;
      const days = Math.ceil(remaining / Math.max(1, dailyRate));
      return new Date(todayMidnight.getFullYear(), todayMidnight.getMonth(), todayMidnight.getDate() + days);
    };

    const date10M = calcEstDate(10000000);
    const date50M = calcEstDate(50000000);
    const date100M = calcEstDate(100000000);

    const endOfYear = new Date(now.getFullYear(), 11, 31);
    const daysToEndOfYear = Math.max(0, Math.round((endOfYear.getTime() - todayMidnight.getTime()) / (1000 * 60 * 60 * 24)));
    const estYearFund = totalLifetime + (daysToEndOfYear * dailyRate);

    // Tet forecast (Grab scoped)
    const nextTet = LunarUtils.getNextTetSolarDate(todayMidnight);
    const daysToTet = Math.max(0, Math.round((nextTet.getTime() - todayMidnight.getTime()) / (1000 * 60 * 60 * 24)));
    const grabEntries = entries.filter(e => isGrabCategory(e.category));
    let grabTotal = 0;
    grabEntries.forEach(e => grabTotal += (e.amount || 0));
    const grabRate = grabEntries.length === 0 ? dailyGoal : (grabTotal / grabEntries.length);
    const estTetFund = grabTotal + (daysToTet * grabRate);

    const formatDateStr = (d) => `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
    const daysUntil = (d) => Math.max(0, Math.round((d.getTime() - todayMidnight.getTime()) / (1000 * 60 * 60 * 24)));

    const renderMilestoneRow = (icon, title, estDate, isAchieved, color) => {
      const days = daysUntil(estDate);
      return `
        <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; background: rgba(15, 23, 42, 0.6); border: 1px solid var(--border-color); border-radius: 12px; margin-bottom: 8px;">
          <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 1.4rem;">${icon}</span>
            <div>
              <div style="font-size: 0.8rem; font-weight: 800; color: ${color};">${title}</div>
              <div style="font-size: 0.7rem; color: var(--text-muted);">${isAchieved ? '🎉 Đã hoàn thành mốc này!' : `Dự kiến: ${formatDateStr(estDate)}`}</div>
            </div>
          </div>
          <div>
            ${isAchieved ? `<span style="font-size: 0.7rem; font-weight: 800; color: #10b981; background: rgba(16, 185, 129, 0.15); padding: 2px 8px; border-radius: 10px;">ĐÃ ĐẠT</span>`
              : `<span style="font-size: 0.7rem; font-weight: 800; color: #38bdf8;">Còn ${days} ngày</span>`}
          </div>
        </div>
      `;
    };

    aiPredictorContent.innerHTML = `
      <div style="display: flex; justify-content: space-around; background: rgba(15, 23, 42, 0.6); border: 1px solid var(--border-color); border-radius: 14px; padding: 12px; text-align: center; margin-bottom: 14px;">
        <div>
          <div style="font-size: 0.7rem; color: var(--text-muted); font-weight: 700;">TỔNG TÍCH LŨY</div>
          <div style="font-size: 1.15rem; font-weight: 900; color: #10b981; margin-top: 2px;">${formatCurrency(totalLifetime)}</div>
        </div>
        <div style="width: 1px; height: 35px; background: var(--border-color);"></div>
        <div>
          <div style="font-size: 0.7rem; color: var(--text-muted); font-weight: 700;">TỐC ĐỘ TRUNG BÌNH</div>
          <div style="font-size: 1.15rem; font-weight: 900; color: #fbbf24; margin-top: 2px;">${formatCurrency(Math.round(dailyRate))}/ngày</div>
        </div>
      </div>

      <div style="font-size: 0.8rem; font-weight: 800; color: var(--text-main); margin-bottom: 8px;">🎯 Cột Mốc Tương Lai Dự Kiến:</div>
      ${renderMilestoneRow('🥇', 'Mốc 10.000.000 VNĐ', date10M, totalLifetime >= 10000000, '#fbbf24')}
      ${renderMilestoneRow('💎', 'Mốc 50.000.000 VNĐ', date50M, totalLifetime >= 50000000, '#38bdf8')}
      ${renderMilestoneRow('👑', 'Mốc 100.000.000 VNĐ', date100M, totalLifetime >= 100000000, '#c084fc')}

      <!-- End of Year -->
      <div style="padding: 10px 12px; background: rgba(251, 191, 36, 0.08); border: 1px solid rgba(251, 191, 36, 0.3); border-radius: 12px; margin-bottom: 8px;">
        <div style="font-size: 0.75rem; font-weight: 800; color: #fbbf24;">📊 Dự Báo Cuối Năm ${now.getFullYear()} (31/12)</div>
        <div style="font-size: 1rem; font-weight: 900; color: var(--text-main); margin: 2px 0;">Dự kiến tích lũy: ${formatCurrency(Math.round(estYearFund))}</div>
        <div style="font-size: 0.675rem; color: var(--text-muted);">Còn đúng ${daysToEndOfYear} ngày nữa hết năm ${now.getFullYear()}</div>
      </div>

      <!-- Tet Forecast -->
      <div style="padding: 10px 12px; background: linear-gradient(135deg, rgba(220,38,38,0.15), rgba(245,158,11,0.15)); border: 1px solid rgba(220,38,38,0.4); border-radius: 12px; margin-bottom: 12px;">
        <div style="font-size: 0.75rem; font-weight: 800; color: #f87171;">🧧 Quỹ Tết Nguyên Đán (Nguồn Grab)</div>
        <div style="font-size: 1rem; font-weight: 900; color: #fef08a; margin: 2px 0;">Dự kiến quỹ ăn Tết: ${formatCurrency(Math.round(estTetFund))}</div>
        <div style="font-size: 0.675rem; color: rgba(255,255,255,0.7);">Còn đúng ${daysToTet} ngày nữa đến Mùng 1 Tết!</div>
      </div>

      <div style="background: rgba(192, 132, 252, 0.1); border: 1px solid rgba(192, 132, 252, 0.3); border-radius: 12px; padding: 10px 12px; text-align: center; font-size: 0.75rem; color: #e9d5ff;">
        🚀 "Tốc độ tiết kiệm của bạn rất kỷ luật! Hãy tiếp tục duy trì mỗi ngày để sớm đạt tự do tài chính!"
      </div>
    `;
  }

  if (drawerAiPredictorBtn) {
    drawerAiPredictorBtn.addEventListener('click', () => {
      closeDrawer();
      renderAiPredictor();
      if (aiPredictorModal) aiPredictorModal.style.display = 'flex';
    });
  }

  if (closeAiPredictorModalBtn) {
    closeAiPredictorModalBtn.addEventListener('click', () => {
      if (aiPredictorModal) aiPredictorModal.style.display = 'none';
    });
  }

  // =========================================================================
  // 🔊 WEB AUDIO SYNTHESIZER (SOUND FX HAPTIC TACTILE FOR COINS & GAMES)
  // =========================================================================
  const SoundFx = {
    ctx: null,
    getCtx: function () {
      if (!this.ctx) {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (AudioCtx) this.ctx = new AudioCtx();
      }
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume();
      }
      return this.ctx;
    },
    playCoinSound: function () {
      try {
        const ctx = this.getCtx();
        if (!ctx) return;
        const now = ctx.currentTime;
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(987.77, now); // B5
        osc.frequency.setValueAtTime(1318.51, now + 0.08); // E6
        gain.gain.setValueAtTime(0.2, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.35);
      } catch (e) {}
    },
    playHitSound: function () {
      try {
        const ctx = this.getCtx();
        if (!ctx) return;
        const now = ctx.currentTime;
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(300, now);
        osc.frequency.exponentialRampToValueAtTime(80, now + 0.15);
        gain.gain.setValueAtTime(0.25, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.15);
      } catch (e) {}
    }
  };

  // =========================================================================
  // 🤖 TRỢ LÝ AI TIẾT KIỆM (GEMINI 3.6 FLASH CHAT ENGINE)
  // =========================================================================
  const GEMINI_KEY_STORAGE = 'savings_custom_gemini_key_v1';
  let customGeminiKey = localStorage.getItem(GEMINI_KEY_STORAGE) || '';

  const fabAiChatBtn = document.getElementById('fabAiChatBtn');
  const drawerAiChatBtn = document.getElementById('drawerAiChatBtn');
  const aiChatModal = document.getElementById('aiChatModal');
  const closeAiChatModalBtn = document.getElementById('closeAiChatModalBtn');
  const aiConfigKeyBtn = document.getElementById('aiConfigKeyBtn');
  const aiChatMessages = document.getElementById('aiChatMessages');
  const aiChatForm = document.getElementById('aiChatForm');
  const aiChatInput = document.getElementById('aiChatInput');
  const geminiKeyModal = document.getElementById('geminiKeyModal');
  const geminiApiKeyInput = document.getElementById('geminiApiKeyInput');
  const saveGeminiKeyBtn = document.getElementById('saveGeminiKeyBtn');
  const closeGeminiKeyModalBtn = document.getElementById('closeGeminiKeyModalBtn');

  function openAiChat() {
    if (aiChatModal) {
      aiChatModal.style.display = 'flex';
      setTimeout(() => { if (aiChatInput) aiChatInput.focus(); }, 100);
    }
  }

  function closeAiChat() {
    if (aiChatModal) aiChatModal.style.display = 'none';
  }

  if (fabAiChatBtn) fabAiChatBtn.addEventListener('click', openAiChat);
  if (drawerAiChatBtn) {
    drawerAiChatBtn.addEventListener('click', () => {
      closeDrawer();
      openAiChat();
    });
  }
  if (closeAiChatModalBtn) closeAiChatModalBtn.addEventListener('click', closeAiChat);

  if (aiConfigKeyBtn) {
    aiConfigKeyBtn.addEventListener('click', () => {
      if (geminiApiKeyInput) geminiApiKeyInput.value = customGeminiKey;
      if (geminiKeyModal) geminiKeyModal.style.display = 'flex';
    });
  }

  if (saveGeminiKeyBtn) {
    saveGeminiKeyBtn.addEventListener('click', () => {
      customGeminiKey = geminiApiKeyInput.value.trim();
      localStorage.setItem(GEMINI_KEY_STORAGE, customGeminiKey);
      if (geminiKeyModal) geminiKeyModal.style.display = 'none';
      alert('✅ Đã lưu Google Gemini API Key thành công!');
    });
  }

  if (closeGeminiKeyModalBtn) {
    closeGeminiKeyModalBtn.addEventListener('click', () => {
      if (geminiKeyModal) geminiKeyModal.style.display = 'none';
    });
  }

  function appendChatMessage(text, sender = 'bot') {
    if (!aiChatMessages) return;
    const div = document.createElement('div');
    div.className = sender === 'user' ? 'ai-msg ai-msg-user' : 'ai-msg ai-msg-bot';
    div.innerHTML = text.replace(/\n/g, '<br>');
    aiChatMessages.appendChild(div);
    aiChatMessages.scrollTop = aiChatMessages.scrollHeight;
  }

  async function askGeminiAi(userPrompt) {
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    let todayAmount = 0;
    entries.filter(e => e.date === todayStr).forEach(e => todayAmount += (e.amount || 0));

    const remaining = Math.max(0, dailyGoal - todayAmount);
    const isTargetAchieved = todayAmount >= dailyGoal;

    let lifetimeTotal = 0;
    entries.forEach(e => lifetimeTotal += (e.amount || 0));

    // Tet countdown
    const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const nextTet = LunarUtils.getNextTetSolarDate(todayMidnight);
    const daysLeftToTet = Math.max(0, Math.round((nextTet.getTime() - todayMidnight.getTime()) / (1000 * 60 * 60 * 24)));
    const grabEntries = entries.filter(e => isGrabCategory(e.category));
    let grabTotal = 0;
    grabEntries.forEach(e => grabTotal += (e.amount || 0));
    const grabRate = grabEntries.length === 0 ? dailyGoal : (grabTotal / grabEntries.length);
    const estTetFund = grabTotal + (daysLeftToTet * grabRate);

    // Fallback offline answers if API key not available or request fails
    const lower = userPrompt.toLowerCase();
    const getOfflineAnswer = () => {
      if (lower.includes('target') || lower.includes('mục tiêu') || lower.includes('còn bao nhiêu') || lower.includes('đủ')) {
        if (isTargetAchieved) {
          return `🎉 Chúc mừng bạn! Hôm nay bạn đã đạt target ${formatCurrency(dailyGoal)} (đã nạp ${formatCurrency(todayAmount)}) rồi nhé! Tiếp tục phát huy nào! 💪`;
        } else {
          return `📌 Hôm nay bạn đã nạp ${formatCurrency(todayAmount)}. Bạn cần tích lũy thêm **${formatCurrency(remaining)}** nữa để hoàn thành mục tiêu ${formatCurrency(dailyGoal)}/ngày hôm nay nhé! 🐷`;
        }
      }
      if (lower.includes('tết') || lower.includes('đếm ngược') || lower.includes('mấy ngày')) {
        return `🧧 Còn đúng **${daysLeftToTet} ngày** nữa là đến Mùng 1 Tết Nguyên Đán! Dự kiến quỹ Tết từ nguồn Grab của bạn sẽ đạt **${formatCurrency(Math.round(estTetFund))}** đó! 🍊`;
      }
      if (lower.includes('hôm nay') || lower.includes('ngày mấy')) {
        const lunarList = LunarUtils.convertSolarToLunar(now.getDate(), now.getMonth() + 1, now.getFullYear());
        const canChiDay = LunarUtils.getCanChiDay(now);
        return `📅 Hôm nay là ngày ${now.getDate()}/${now.getMonth() + 1}/${now.getFullYear()} Dương Lịch (tức ngày ${lunarList[0]} tháng ${lunarList[1]} Âm Lịch, Ngày ${canChiDay}). Đừng quên cập nhật sổ tiết kiệm nhé! ✨`;
      }
      if (lower.includes('lời khuyên') || lower.includes('mẹo') || lower.includes('tư vấn')) {
        return `💡 **Mẹo Quản Lý Tài Chính:** Hãy trích ra tối thiểu 10% thu nhập mỗi khi kết thúc ca chạy Grab, duy trì đều đặn mỗi ngày để hình thành phản xạ kỷ luật tích lũy! 🚀`;
      }
      return `🤖 Trợ Lý AI Tiết Kiệm chào bạn! Hôm nay bạn đã nạp ${formatCurrency(todayAmount)} / target ${formatCurrency(dailyGoal)}. Còn ${daysLeftToTet} ngày nữa là tới Tết, cùng nhau cố gắng nhé! 🌟`;
    };

    if (!customGeminiKey) {
      return getOfflineAnswer();
    }

    try {
      const systemInstruction = `Bạn là "Trợ Lý AI Tiết Kiệm" trong ứng dụng "Sổ Tiết Kiệm Daily". Hãy trả lời ngắn gọn (2-4 câu), hào hứng, thân thiện, dùng emoji sinh động dựa trên dữ liệu thật của người dùng:
- Mục tiêu ngày: ${dailyGoal} đ
- Đã nạp hôm nay: ${todayAmount} đ (${isTargetAchieved ? 'ĐÃ ĐẠT TARGET' : 'CÒN THIẾU ' + remaining + ' đ'})
- Tổng tích lũy trọn đời: ${lifetimeTotal} đ
- Đếm ngược đến Mùng 1 Tết: ${daysLeftToTet} ngày (Quỹ Tết dự kiến: ${Math.round(estTetFund)} đ)`;

      const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${customGeminiKey}`;
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: `${systemInstruction}\n\n[CÂU HỎI]: ${userPrompt}` }] }]
        })
      });

      if (res.ok) {
        const data = await res.json();
        const cand = data.candidates && data.candidates[0];
        const text = cand && cand.content && cand.content.parts && cand.content.parts[0] && cand.content.parts[0].text;
        if (text) return text.trim();
      }
    } catch (e) {
      console.warn('Gemini API fetch error:', e);
    }
    return getOfflineAnswer();
  }

  if (aiChatForm) {
    aiChatForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const text = aiChatInput.value.trim();
      if (!text) return;
      aiChatInput.value = '';
      appendChatMessage(text, 'user');

      // Add loading indicator
      const loadingDiv = document.createElement('div');
      loadingDiv.className = 'ai-msg ai-msg-loading';
      loadingDiv.innerHTML = '⏳ AI đang suy nghĩ...';
      aiChatMessages.appendChild(loadingDiv);
      aiChatMessages.scrollTop = aiChatMessages.scrollHeight;

      const reply = await askGeminiAi(text);
      loadingDiv.remove();
      appendChatMessage(reply, 'bot');
    });
  }

  // Quick Chips
  document.querySelectorAll('.ai-quick-chip').forEach(chip => {
    chip.addEventListener('click', async () => {
      const prompt = chip.getAttribute('data-prompt');
      if (!prompt) return;
      appendChatMessage(prompt, 'user');

      const loadingDiv = document.createElement('div');
      loadingDiv.className = 'ai-msg ai-msg-loading';
      loadingDiv.innerHTML = '⏳ AI đang suy nghĩ...';
      aiChatMessages.appendChild(loadingDiv);
      aiChatMessages.scrollTop = aiChatMessages.scrollHeight;

      const reply = await askGeminiAi(prompt);
      loadingDiv.remove();
      appendChatMessage(reply, 'bot');
    });
  });

  // =========================================================================
  // 🕹️ GAME XẾP GẠCH TETRIS (CANVAS 60 FPS CONTROLLER)
  // =========================================================================
  const drawerTetrisBtn = document.getElementById('drawerTetrisBtn');
  const tetrisModal = document.getElementById('tetrisModal');
  const closeTetrisModalBtn = document.getElementById('closeTetrisModalBtn');
  const tetrisCanvas = document.getElementById('tetrisCanvas');
  const tetrisScoreDisplay = document.getElementById('tetrisScore');
  const tetrisLinesDisplay = document.getElementById('tetrisLines');
  const tetrisLeftBtn = document.getElementById('tetrisLeftBtn');
  const tetrisRotateBtn = document.getElementById('tetrisRotateBtn');
  const tetrisRightBtn = document.getElementById('tetrisRightBtn');
  const tetrisDownBtn = document.getElementById('tetrisDownBtn');
  const tetrisDropBtn = document.getElementById('tetrisDropBtn');
  const tetrisRestartBtn = document.getElementById('tetrisRestartBtn');

  const Tetris = {
    rows: 20,
    cols: 10,
    gridSize: 20,
    board: [],
    timer: null,
    score: 0,
    lines: 0,
    currentPiece: null,
    currentX: 3,
    currentY: 0,
    currentColor: '#38bdf8',
    shapes: [
      { color: '#06b6d4', shape: [[1, 1, 1, 1]] }, // I
      { color: '#eab308', shape: [[1, 1], [1, 1]] }, // O
      { color: '#a855f7', shape: [[0, 1, 0], [1, 1, 1]] }, // T
      { color: '#22c55e', shape: [[0, 1, 1], [1, 1, 0]] }, // S
      { color: '#ef4444', shape: [[1, 1, 0], [0, 1, 1]] }, // Z
      { color: '#3b82f6', shape: [[1, 0, 0], [1, 1, 1]] }, // J
      { color: '#f97316', shape: [[0, 0, 1], [1, 1, 1]] }  // L
    ],
    init: function () {
      this.board = Array.from({ length: this.rows }, () => Array(this.cols).fill(null));
      this.score = 0;
      this.lines = 0;
      this.updateScore();
      this.spawn();
      this.start();
    },
    updateScore: function () {
      if (tetrisScoreDisplay) tetrisScoreDisplay.textContent = this.score;
      if (tetrisLinesDisplay) tetrisLinesDisplay.textContent = this.lines;
    },
    spawn: function () {
      const idx = Math.floor(Math.random() * this.shapes.length);
      const pieceData = this.shapes[idx];
      this.currentPiece = pieceData.shape;
      this.currentColor = pieceData.color;
      this.currentX = Math.floor((this.cols - this.currentPiece[0].length) / 2);
      this.currentY = 0;
      if (this.checkCollision(this.currentX, this.currentY, this.currentPiece)) {
        this.gameOver();
      }
    },
    checkCollision: function (x, y, piece) {
      for (let r = 0; r < piece.length; r++) {
        for (let c = 0; c < piece[r].length; c++) {
          if (piece[r][c]) {
            const newX = x + c;
            const newY = y + r;
            if (newX < 0 || newX >= this.cols || newY >= this.rows) return true;
            if (newY >= 0 && this.board[newY][newX]) return true;
          }
        }
      }
      return false;
    },
    rotate: function () {
      if (!this.currentPiece) return;
      const rotated = Array.from({ length: this.currentPiece[0].length }, (_, i) =>
        this.currentPiece.map(row => row[row.length - 1 - i])
      );
      if (!this.checkCollision(this.currentX, this.currentY, rotated)) {
        this.currentPiece = rotated;
        this.draw();
      }
    },
    moveLeft: function () {
      if (!this.checkCollision(this.currentX - 1, this.currentY, this.currentPiece)) {
        this.currentX--;
        this.draw();
      }
    },
    moveRight: function () {
      if (!this.checkCollision(this.currentX + 1, this.currentY, this.currentPiece)) {
        this.currentX++;
        this.draw();
      }
    },
    moveDown: function () {
      if (!this.checkCollision(this.currentX, this.currentY + 1, this.currentPiece)) {
        this.currentY++;
        this.draw();
      } else {
        this.lock();
      }
    },
    dropFast: function () {
      while (!this.checkCollision(this.currentX, this.currentY + 1, this.currentPiece)) {
        this.currentY++;
      }
      this.lock();
    },
    lock: function () {
      for (let r = 0; r < this.currentPiece.length; r++) {
        for (let c = 0; c < this.currentPiece[r].length; c++) {
          if (this.currentPiece[r][c] && this.currentY + r >= 0) {
            this.board[this.currentY + r][this.currentX + c] = this.currentColor;
          }
        }
      }
      this.clearLines();
      this.spawn();
      this.draw();
    },
    clearLines: function () {
      let cleared = 0;
      for (let r = this.rows - 1; r >= 0; r--) {
        if (this.board[r].every(cell => cell !== null)) {
          this.board.splice(r, 1);
          this.board.unshift(Array(this.cols).fill(null));
          cleared++;
          r++; // Recheck
        }
      }
      if (cleared > 0) {
        SoundFx.playCoinSound();
        this.lines += cleared;
        this.score += cleared * 100;
        this.updateScore();
      }
    },
    start: function () {
      clearInterval(this.timer);
      this.timer = setInterval(() => this.moveDown(), 500);
      this.draw();
    },
    stop: function () {
      clearInterval(this.timer);
    },
    gameOver: function () {
      this.stop();
      SoundFx.playHitSound();
      alert(`🎮 Trò chơi kết thúc! Điểm của bạn: ${this.score}`);
    },
    draw: function () {
      if (!tetrisCanvas) return;
      const ctx = tetrisCanvas.getContext('2d');
      ctx.fillStyle = '#020617';
      ctx.fillRect(0, 0, tetrisCanvas.width, tetrisCanvas.height);

      // Grid lines
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
      for (let r = 0; r < this.rows; r++) {
        for (let c = 0; c < this.cols; c++) {
          ctx.strokeRect(c * this.gridSize, r * this.gridSize, this.gridSize, this.gridSize);
        }
      }

      // Placed blocks
      for (let r = 0; r < this.rows; r++) {
        for (let c = 0; c < this.cols; c++) {
          if (this.board[r][c]) {
            ctx.fillStyle = this.board[r][c];
            ctx.fillRect(c * this.gridSize + 1, r * this.gridSize + 1, this.gridSize - 2, this.gridSize - 2);
          }
        }
      }

      // Current falling piece
      if (this.currentPiece) {
        ctx.fillStyle = this.currentColor;
        for (let r = 0; r < this.currentPiece.length; r++) {
          for (let c = 0; c < this.currentPiece[r].length; c++) {
            if (this.currentPiece[r][c]) {
              ctx.fillRect((this.currentX + c) * this.gridSize + 1, (this.currentY + r) * this.gridSize + 1, this.gridSize - 2, this.gridSize - 2);
            }
          }
        }
      }
    }
  };

  if (drawerTetrisBtn) {
    drawerTetrisBtn.addEventListener('click', () => {
      closeDrawer();
      if (tetrisModal) {
        tetrisModal.style.display = 'flex';
        Tetris.init();
      }
    });
  }
  if (closeTetrisModalBtn) {
    closeTetrisModalBtn.addEventListener('click', () => {
      Tetris.stop();
      if (tetrisModal) tetrisModal.style.display = 'none';
    });
  }
  if (tetrisLeftBtn) tetrisLeftBtn.addEventListener('click', () => Tetris.moveLeft());
  if (tetrisRightBtn) tetrisRightBtn.addEventListener('click', () => Tetris.moveRight());
  if (tetrisRotateBtn) tetrisRotateBtn.addEventListener('click', () => Tetris.rotate());
  if (tetrisDownBtn) tetrisDownBtn.addEventListener('click', () => Tetris.moveDown());
  if (tetrisDropBtn) tetrisDropBtn.addEventListener('click', () => Tetris.dropFast());
  if (tetrisRestartBtn) tetrisRestartBtn.addEventListener('click', () => Tetris.init());

  // =========================================================================
  // 🐷 GAME CHÚ LỢN BAY (FLAPPY PIGGY CONTROLLER)
  // =========================================================================
  const drawerFlappyBtn = document.getElementById('drawerFlappyBtn');
  const flappyModal = document.getElementById('flappyModal');
  const closeFlappyModalBtn = document.getElementById('closeFlappyModalBtn');
  const flappyCanvas = document.getElementById('flappyCanvas');
  const flappyScoreDisplay = document.getElementById('flappyScore');
  const flappyHighScoreDisplay = document.getElementById('flappyHighScore');
  const flappyRestartBtn = document.getElementById('flappyRestartBtn');

  const Flappy = {
    pigX: 60,
    pigY: 190,
    velocity: 0,
    gravity: 0.35,
    jump: -5.5,
    pigRadius: 13,
    score: 0,
    highScore: 0,
    pipes: [],
    timer: null,
    isPlaying: false,
    init: function () {
      this.pigY = 190;
      this.velocity = 0;
      this.score = 0;
      this.pipes = [];
      this.spawnPipe(320);
      this.spawnPipe(490);
      this.isPlaying = true;
      if (flappyRestartBtn) flappyRestartBtn.style.display = 'none';
      this.updateScore();
      clearInterval(this.timer);
      this.timer = setInterval(() => this.loop(), 24);
    },
    updateScore: function () {
      if (flappyScoreDisplay) flappyScoreDisplay.textContent = this.score;
      if (flappyHighScoreDisplay) flappyHighScoreDisplay.textContent = this.highScore;
    },
    spawnPipe: function (x) {
      const gap = 110;
      const minH = 40;
      const maxH = 380 - gap - minH;
      const topHeight = minH + Math.random() * (maxH - minH);
      this.pipes.push({ x: x, topHeight: topHeight, gap: gap, passed: false });
    },
    flap: function () {
      if (!this.isPlaying) {
        this.init();
        return;
      }
      this.velocity = this.jump;
    },
    loop: function () {
      this.velocity += this.gravity;
      this.pigY += this.velocity;

      // Ground/Ceiling hit
      if (this.pigY - this.pigRadius <= 0 || this.pigY + this.pigRadius >= 380) {
        this.die();
        return;
      }

      // Pipes update
      for (let p of this.pipes) {
        p.x -= 2.6;
        if (!p.passed && p.x + 44 < this.pigX) {
          p.passed = true;
          this.score++;
          if (this.score > this.highScore) this.highScore = this.score;
          this.updateScore();
          SoundFx.playCoinSound();
        }

        // Collision check
        if (this.pigX + this.pigRadius > p.x && this.pigX - this.pigRadius < p.x + 44) {
          if (this.pigY - this.pigRadius < p.topHeight || this.pigY + this.pigRadius > p.topHeight + p.gap) {
            this.die();
            return;
          }
        }
      }

      // Recycle pipe
      if (this.pipes.length > 0 && this.pipes[0].x < -50) {
        this.pipes.shift();
        this.spawnPipe(this.pipes[this.pipes.length - 1].x + 160);
      }

      this.draw();
    },
    die: function () {
      this.isPlaying = false;
      clearInterval(this.timer);
      SoundFx.playHitSound();
      if (flappyRestartBtn) flappyRestartBtn.style.display = 'block';
      this.draw();
    },
    draw: function () {
      if (!flappyCanvas) return;
      const ctx = flappyCanvas.getContext('2d');
      ctx.fillStyle = '#0f172a';
      ctx.fillRect(0, 0, 280, 380);

      // Draw Pipes
      for (let p of this.pipes) {
        ctx.fillStyle = '#10b981';
        // Top
        ctx.fillRect(p.x, 0, 44, p.topHeight);
        ctx.fillStyle = '#059669';
        ctx.fillRect(p.x - 2, p.topHeight - 12, 48, 12);

        // Bottom
        ctx.fillStyle = '#10b981';
        const bottomY = p.topHeight + p.gap;
        ctx.fillRect(p.x, bottomY, 44, 380 - bottomY);
        ctx.fillStyle = '#059669';
        ctx.fillRect(p.x - 2, bottomY, 48, 12);
      }

      // Draw Piggy
      ctx.save();
      ctx.translate(this.pigX, this.pigY);
      const rot = Math.max(-0.5, Math.min(0.5, this.velocity / 10));
      ctx.rotate(rot);

      // Piggy Body
      ctx.fillStyle = '#f472b6';
      ctx.beginPath();
      ctx.arc(0, 0, this.pigRadius, 0, Math.PI * 2);
      ctx.fill();

      // Snout
      ctx.fillStyle = '#ec4899';
      ctx.beginPath();
      ctx.ellipse(6, 2, 4, 3, 0, 0, Math.PI * 2);
      ctx.fill();

      // Eye
      ctx.fillStyle = '#000000';
      ctx.beginPath();
      ctx.arc(4, -4, 2, 0, Math.PI * 2);
      ctx.fill();

      // Wing
      ctx.fillStyle = '#ffffff';
      ctx.beginPath();
      ctx.moveTo(-4, 0);
      ctx.quadraticCurveTo(-12, this.velocity < 0 ? -12 : 2, -4, 6);
      ctx.fill();

      ctx.restore();
    }
  };

  if (drawerFlappyBtn) {
    drawerFlappyBtn.addEventListener('click', () => {
      closeDrawer();
      if (flappyModal) {
        flappyModal.style.display = 'flex';
        Flappy.init();
      }
    });
  }
  if (closeFlappyModalBtn) {
    closeFlappyModalBtn.addEventListener('click', () => {
      clearInterval(Flappy.timer);
      if (flappyModal) flappyModal.style.display = 'none';
    });
  }
  if (flappyCanvas) flappyCanvas.addEventListener('click', () => Flappy.flap());
  if (flappyRestartBtn) flappyRestartBtn.addEventListener('click', () => Flappy.init());

  window.addEventListener('keydown', (e) => {
    if (e.code === 'Space') {
      if (flappyModal && flappyModal.style.display !== 'none') {
        e.preventDefault();
        Flappy.flap();
      }
      if (dartsModal && dartsModal.style.display !== 'none') {
        e.preventDefault();
        Darts.throw();
      }
    }
  });

  // =========================================================================
  // 🎯 GAME PHI TIÊU GIẢI TỎA CĂNG THẲNG (DARTS CONTROLLER)
  // =========================================================================
  const drawerDartsBtn = document.getElementById('drawerDartsBtn');
  const dartsModal = document.getElementById('dartsModal');
  const closeDartsModalBtn = document.getElementById('closeDartsModalBtn');
  const dartsCanvas = document.getElementById('dartsCanvas');
  const dartsScoreDisplay = document.getElementById('dartsScore');
  const dartsLeftDisplay = document.getElementById('dartsLeft');
  const dartsHighScoreDisplay = document.getElementById('dartsHighScore');
  const dartsHitFeedback = document.getElementById('dartsHitFeedback');
  const dartsThrowBtn = document.getElementById('dartsThrowBtn');
  const dartsRestartBtn = document.getElementById('dartsRestartBtn');

  const Darts = {
    targetX: 140,
    targetY: 100,
    targetDir: 2.2,
    aimX: 140,
    aimDir: 2.8,
    power: 0.0,
    powerInc: true,
    dartsLeft: 5,
    score: 0,
    highScore: 0,
    timer: null,
    landPos: null,
    isFlying: false,
    init: function () {
      this.dartsLeft = 5;
      this.score = 0;
      this.landPos = null;
      this.isFlying = false;
      if (dartsRestartBtn) dartsRestartBtn.style.display = 'none';
      if (dartsHitFeedback) dartsHitFeedback.textContent = '';
      this.updateScore();
      clearInterval(this.timer);
      this.timer = setInterval(() => this.loop(), 20);
    },
    updateScore: function () {
      if (dartsScoreDisplay) dartsScoreDisplay.textContent = this.score;
      if (dartsLeftDisplay) dartsLeftDisplay.textContent = `🎯 x ${this.dartsLeft}`;
      if (dartsHighScoreDisplay) dartsHighScoreDisplay.textContent = this.highScore;
    },
    throw: function () {
      if (this.isFlying || this.dartsLeft <= 0) return;
      this.isFlying = true;
      this.dartsLeft--;
      this.updateScore();

      const landX = this.aimX + (Math.random() * 12 - 6);
      const landY = this.targetY + (1.0 - this.power) * 70 - 35;
      this.landPos = { x: landX, y: landY };

      const dist = Math.sqrt(Math.pow(landX - this.targetX, 2) + Math.pow(landY - this.targetY, 2));
      let pts = 0;
      let text = '';
      if (dist < 12) {
        pts = 100;
        text = '🎯 BULLSEYE! +100 ĐIỂM';
        SoundFx.playCoinSound();
      } else if (dist < 28) {
        pts = 50;
        text = '🌟 VÒNG VÀNG! +50 ĐIỂM';
        SoundFx.playCoinSound();
      } else if (dist < 46) {
        pts = 30;
        text = '🔵 VÒNG XANH! +30 ĐIỂM';
      } else if (dist < 64) {
        pts = 10;
        text = '⚪ VÒNG NGOÀI! +10 ĐIỂM';
      } else {
        pts = 0;
        text = '❌ TRỤT BIA! 0 ĐIỂM';
        SoundFx.playHitSound();
      }

      this.score += pts;
      if (this.score > this.highScore) this.highScore = this.score;
      if (dartsHitFeedback) dartsHitFeedback.textContent = text;
      this.updateScore();

      setTimeout(() => {
        this.isFlying = false;
        if (this.dartsLeft <= 0) {
          if (dartsRestartBtn) dartsRestartBtn.style.display = 'block';
        }
      }, 700);
    },
    loop: function () {
      // Move Target
      this.targetX += this.targetDir;
      if (this.targetX < 60 || this.targetX > 220) this.targetDir = -this.targetDir;

      // Move Aim Line
      this.aimX += this.aimDir;
      if (this.aimX < 40 || this.aimX > 240) this.aimDir = -this.aimDir;

      // Power oscillation
      if (this.powerInc) {
        this.power += 0.035;
        if (this.power >= 1.0) { this.power = 1.0; this.powerInc = false; }
      } else {
        this.power -= 0.035;
        if (this.power <= 0.0) { this.power = 0.0; this.powerInc = true; }
      }

      this.draw();
    },
    draw: function () {
      if (!dartsCanvas) return;
      const ctx = dartsCanvas.getContext('2d');
      ctx.fillStyle = '#0f172a';
      ctx.fillRect(0, 0, 280, 320);

      // Draw Bullseye Target Circles
      const rings = [
        { r: 64, color: '#e2e8f0' },
        { r: 46, color: '#38bdf8' },
        { r: 28, color: '#fbbf24' },
        { r: 12, color: '#ef4444' }
      ];
      for (let ring of rings) {
        ctx.fillStyle = ring.color;
        ctx.beginPath();
        ctx.arc(this.targetX, this.targetY, ring.r, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = 'rgba(0,0,0,0.2)';
        ctx.stroke();
      }

      // Draw Aim Line
      ctx.strokeStyle = '#38bdf8';
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(this.aimX, 0);
      ctx.lineTo(this.aimX, 280);
      ctx.stroke();
      ctx.setLineDash([]);

      // Draw Power Bar at bottom
      ctx.fillStyle = 'rgba(255,255,255,0.1)';
      ctx.fillRect(30, 290, 220, 14);
      ctx.fillStyle = this.power > 0.8 ? '#ef4444' : (this.power > 0.4 ? '#fbbf24' : '#10b981');
      ctx.fillRect(30, 290, 220 * this.power, 14);

      // Draw Landed Dart
      if (this.landPos) {
        ctx.fillStyle = '#fbbf24';
        ctx.beginPath();
        ctx.arc(this.landPos.x, this.landPos.y, 4, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#ffffff';
        ctx.beginPath();
        ctx.moveTo(this.landPos.x, this.landPos.y);
        ctx.lineTo(this.landPos.x + 8, this.landPos.y + 12);
        ctx.stroke();
      }
    }
  };

  if (drawerDartsBtn) {
    drawerDartsBtn.addEventListener('click', () => {
      closeDrawer();
      if (dartsModal) {
        dartsModal.style.display = 'flex';
        Darts.init();
      }
    });
  }
  if (closeDartsModalBtn) {
    closeDartsModalBtn.addEventListener('click', () => {
      clearInterval(Darts.timer);
      if (dartsModal) dartsModal.style.display = 'none';
    });
  }
  if (dartsThrowBtn) dartsThrowBtn.addEventListener('click', () => Darts.throw());
  if (dartsRestartBtn) dartsRestartBtn.addEventListener('click', () => Darts.init());

  // App Initialize
  initSupabase();
  seedInitialSampleData();
  loadWishlistGoals();
  setDefaultDate();
  entryAmount.value = formatMoneyInput(dailyGoal);
  updateEntryPreview();
  renderDrawerInfo();
  refreshAll();

  // Retry on window load for local file:/// protocol
  window.addEventListener('load', () => {
    initSupabase();
    renderDrawerInfo();
  });
})();


