// ============================================
// CineFlow Admin Panel - JavaScript
// ============================================


const firebaseConfig = {
  apiKey: "AIzaSyAqvfTFpri7-quRf8uKf9lKjQElQuBUTu8",
  authDomain: "cineflow-2e9c1.firebaseapp.com",
  projectId: "cineflow-2e9c1",
  storageBucket: "cineflow-2e9c1.firebasestorage.app",
  messagingSenderId: "913914551498",
  appId: "1:913914551498:android:44ff1f4e4bb54e04c0a37f"
};

// Inicializa Firebase
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();

// Estado da aplicação
let currentUser = null;
let authToken = null;
let allUsers = [];
let selectedUserToBlock = null;

// API Base URL
const API_URL = window.location.origin;

// ============================================
// Autenticação
// ============================================

// Login
document.getElementById('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const email = document.getElementById('login-email').value;
  const password = document.getElementById('login-password').value;
  const loginBtn = document.getElementById('login-btn');
  const errorDiv = document.getElementById('login-error');
  
  loginBtn.disabled = true;
  loginBtn.innerHTML = '<span class="material-icons-round">hourglass_empty</span> Entrando...';
  errorDiv.classList.remove('show');
  
  try {
    const userCredential = await auth.signInWithEmailAndPassword(email, password);
    currentUser = userCredential.user;
    authToken = await currentUser.getIdToken();
    
    // Testa se é admin
    const testResponse = await fetch(`${API_URL}/api/admin/stats`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    if (testResponse.status === 403) {
      throw new Error('Você não tem permissão de administrador.');
    }
    
    if (!testResponse.ok) {
      throw new Error('Erro ao verificar permissões.');
    }
    
    showDashboard();
  } catch (error) {
    console.error('Erro no login:', error);
    errorDiv.textContent = error.code === 'auth/wrong-password' 
      ? 'Senha incorreta' 
      : error.code === 'auth/user-not-found'
      ? 'Usuário não encontrado'
      : error.message;
    errorDiv.classList.add('show');
  } finally {
    loginBtn.disabled = false;
    loginBtn.innerHTML = '<span class="material-icons-round">login</span> Entrar';
  }
});

// Logout
document.getElementById('logout-btn').addEventListener('click', async () => {
  await auth.signOut();
  currentUser = null;
  authToken = null;
  showLogin();
});

// ============================================
// Navegação
// ============================================

function showLogin() {
  document.getElementById('login-screen').classList.add('active');
  document.getElementById('dashboard-screen').classList.remove('active');
}

function showDashboard() {
  document.getElementById('login-screen').classList.remove('active');
  document.getElementById('dashboard-screen').classList.add('active');
  
  // Atualiza info do admin
  document.getElementById('admin-name').textContent = currentUser.displayName || 'Admin';
  document.getElementById('admin-email').textContent = currentUser.email;
  document.getElementById('admin-avatar').textContent = 
    (currentUser.displayName || currentUser.email)[0].toUpperCase();
  
  // Carrega dados
  loadDashboard();
}

// Navegação da sidebar
document.querySelectorAll('.nav-item').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault();
    const section = e.currentTarget.dataset.section;
    
    // Atualiza nav ativa
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
    e.currentTarget.classList.add('active');
    
    // Mostra seção
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.getElementById(`section-${section}`).classList.add('active');
    
    // Carrega dados da seção
    if (section === 'dashboard') loadDashboard();
    if (section === 'users') loadUsers();
    if (section === 'updates') loadAppConfig();
  });
});

// ============================================
// Dashboard
// ============================================

async function loadDashboard() {
  try {
    const response = await fetch(`${API_URL}/api/admin/stats`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    if (!response.ok) throw new Error('Erro ao carregar estatísticas');
    
    const stats = await response.json();
    
    document.getElementById('stat-total-users').textContent = stats.totalUsers;
    document.getElementById('stat-active-users').textContent = stats.activeUsers;
    document.getElementById('stat-blocked-users').textContent = stats.blockedUsers;
    document.getElementById('stat-recent-users').textContent = stats.recentUsers;
    
    // Carrega usuários recentes
    await loadRecentUsers();
  } catch (error) {
    console.error('Erro no dashboard:', error);
    showToast('Erro ao carregar dashboard', 'error');
  }
}

async function loadRecentUsers() {
  try {
    const response = await fetch(`${API_URL}/api/admin/users`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    if (!response.ok) throw new Error('Erro ao carregar usuários');
    
    const data = await response.json();
    allUsers = data.users;
    
    // Pega os 5 mais recentes
    const recent = allUsers
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5);
    
    const container = document.getElementById('recent-users-list');
    container.innerHTML = recent.map(user => `
      <div class="user-preview-item">
        <div class="user-avatar">${(user.displayName || user.email)[0].toUpperCase()}</div>
        <div class="user-preview-info">
          <strong>${user.displayName}</strong>
          <span>${user.email}</span>
        </div>
        <span class="status-badge ${user.isBlocked ? 'status-blocked' : 'status-active'}">
          ${user.isBlocked ? 'Bloqueado' : 'Ativo'}
        </span>
      </div>
    `).join('');
  } catch (error) {
    console.error('Erro ao carregar usuários recentes:', error);
  }
}

// ============================================
// Usuários
// ============================================

async function loadUsers() {
  try {
    const response = await fetch(`${API_URL}/api/admin/users`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    if (!response.ok) throw new Error('Erro ao carregar usuários');
    
    const data = await response.json();
    allUsers = data.users;
    
    renderUsers(allUsers);
  } catch (error) {
    console.error('Erro ao carregar usuários:', error);
    showToast('Erro ao carregar usuários', 'error');
  }
}

function renderUsers(users) {
  const tbody = document.getElementById('users-table-body');
  
  tbody.innerHTML = users.map(user => `
    <tr>
      <td>
        <div class="user-cell">
          <div class="user-avatar">${(user.displayName || user.email)[0].toUpperCase()}</div>
          <span>${user.displayName}</span>
        </div>
      </td>
      <td>${user.email}</td>
      <td>${formatDate(user.createdAt)}</td>
      <td>${formatDate(user.lastSignIn)}</td>
      <td>
        <span class="status-badge ${user.isBlocked ? 'status-blocked' : 'status-active'}">
          <span class="material-icons-round" style="font-size: 14px;">
            ${user.isBlocked ? 'block' : 'check_circle'}
          </span>
          ${user.isBlocked ? 'Bloqueado' : 'Ativo'}
        </span>
      </td>
      <td>
        ${user.isBlocked 
          ? `<button class="action-btn unblock" onclick="unblockUser('${user.uid}')" title="Desbloquear">
               <span class="material-icons-round">lock_open</span>
             </button>`
          : `<button class="action-btn block" onclick="openBlockModal('${user.uid}', '${user.email}')" title="Bloquear">
               <span class="material-icons-round">block</span>
             </button>`
        }
      </td>
    </tr>
  `).join('');
}

// Busca de usuários
document.getElementById('user-search').addEventListener('input', (e) => {
  const query = e.target.value.toLowerCase();
  const filtered = allUsers.filter(u => 
    u.email.toLowerCase().includes(query) || 
    (u.displayName && u.displayName.toLowerCase().includes(query))
  );
  renderUsers(filtered);
});

// Modal de bloqueio
function openBlockModal(uid, email) {
  selectedUserToBlock = uid;
  document.getElementById('user-to-block-info').textContent = email;
  document.getElementById('block-reason').value = '';
  document.getElementById('block-modal').classList.add('show');
}

function closeBlockModal() {
  selectedUserToBlock = null;
  document.getElementById('block-modal').classList.remove('show');
}

// Confirma bloqueio
document.getElementById('confirm-block-btn').addEventListener('click', async () => {
  if (!selectedUserToBlock) return;
  
  const reason = document.getElementById('block-reason').value;
  
  try {
    const response = await fetch(`${API_URL}/api/admin/users/${selectedUserToBlock}/block`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ block: true, reason })
    });
    
    if (!response.ok) throw new Error('Erro ao bloquear');
    
    closeBlockModal();
    showToast('Usuário bloqueado com sucesso', 'success');
    loadUsers();
    loadDashboard();
  } catch (error) {
    console.error('Erro ao bloquear:', error);
    showToast('Erro ao bloquear usuário', 'error');
  }
});

// Desbloquear usuário
async function unblockUser(uid) {
  try {
    const response = await fetch(`${API_URL}/api/admin/users/${uid}/block`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ block: false })
    });
    
    if (!response.ok) throw new Error('Erro ao desbloquear');
    
    showToast('Usuário desbloqueado com sucesso', 'success');
    loadUsers();
    loadDashboard();
  } catch (error) {
    console.error('Erro ao desbloquear:', error);
    showToast('Erro ao desbloquear usuário', 'error');
  }
}

// ============================================
// Atualizações do App
// ============================================

async function loadAppConfig() {
  try {
    const response = await fetch(`${API_URL}/api/app-version`);
    const config = await response.json();
    
    document.getElementById('min-version').value = config.minVersion || '1.0.0';
    document.getElementById('force-update').checked = config.forceUpdate || false;
    document.getElementById('update-message').value = config.updateMessage || '';
    document.getElementById('download-url').value = config.downloadUrl || '';
    document.getElementById('upload-version').value = config.minVersion || '1.0.0';
    
    // Carrega info do APK atual
    loadCurrentApkInfo();
  } catch (error) {
    console.error('Erro ao carregar configuração:', error);
  }
}

// ============================================
// Upload de APK
// ============================================

let selectedFile = null;

// Drop zone eventos
const dropZone = document.getElementById('drop-zone');
const fileInput = document.getElementById('apk-file');

dropZone.addEventListener('dragover', (e) => {
  e.preventDefault();
  dropZone.classList.add('dragover');
});

dropZone.addEventListener('dragleave', () => {
  dropZone.classList.remove('dragover');
});

dropZone.addEventListener('drop', (e) => {
  e.preventDefault();
  dropZone.classList.remove('dragover');
  
  const file = e.dataTransfer.files[0];
  if (file && file.name.endsWith('.apk')) {
    handleFileSelect(file);
  } else {
    showToast('Apenas arquivos .apk são permitidos', 'error');
  }
});

fileInput.addEventListener('change', (e) => {
  if (e.target.files[0]) {
    handleFileSelect(e.target.files[0]);
  }
});

function handleFileSelect(file) {
  selectedFile = file;
  
  const sizeMB = (file.size / (1024 * 1024)).toFixed(2);
  document.getElementById('file-name').textContent = file.name;
  document.getElementById('file-size').textContent = sizeMB + ' MB';
  
  document.getElementById('drop-zone').style.display = 'none';
  document.getElementById('file-info').style.display = 'flex';
}

function removeFile() {
  selectedFile = null;
  fileInput.value = '';
  document.getElementById('drop-zone').style.display = 'block';
  document.getElementById('file-info').style.display = 'none';
}

async function uploadAPK() {
  if (!selectedFile) {
    showToast('Selecione um arquivo APK primeiro', 'error');
    return;
  }
  
  const version = document.getElementById('upload-version').value;
  const uploadBtn = document.getElementById('upload-btn');
  const progressContainer = document.getElementById('upload-progress');
  const progressFill = document.getElementById('progress-fill');
  const progressText = document.getElementById('progress-text');
  
  // Mostra progress
  progressContainer.style.display = 'flex';
  uploadBtn.disabled = true;
  uploadBtn.innerHTML = '<span class="material-icons-round">hourglass_empty</span> Enviando...';
  
  const formData = new FormData();
  formData.append('apk', selectedFile);
  formData.append('version', version);
  
  try {
    const xhr = new XMLHttpRequest();
    
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const percent = Math.round((e.loaded / e.total) * 100);
        progressFill.style.width = percent + '%';
        progressText.textContent = percent + '%';
      }
    });
    
    xhr.onload = function() {
      if (xhr.status === 200) {
        const response = JSON.parse(xhr.responseText);
        showToast('APK enviado com sucesso!', 'success');
        
        // Atualiza campos
        document.getElementById('download-url').value = response.file.downloadUrl;
        document.getElementById('min-version').value = version;
        
        // Reseta upload
        removeFile();
        loadCurrentApkInfo();
      } else {
        const error = JSON.parse(xhr.responseText);
        showToast(error.error || 'Erro ao enviar APK', 'error');
      }
      
      uploadBtn.disabled = false;
      uploadBtn.innerHTML = '<span class="material-icons-round">cloud_upload</span> Enviar APK';
      progressContainer.style.display = 'none';
      progressFill.style.width = '0%';
    };
    
    xhr.onerror = function() {
      showToast('Erro de conexão ao enviar APK', 'error');
      uploadBtn.disabled = false;
      uploadBtn.innerHTML = '<span class="material-icons-round">cloud_upload</span> Enviar APK';
      progressContainer.style.display = 'none';
    };
    
    xhr.open('POST', `${API_URL}/api/admin/upload-apk`);
    xhr.setRequestHeader('Authorization', `Bearer ${authToken}`);
    xhr.send(formData);
    
  } catch (error) {
    console.error('Erro no upload:', error);
    showToast('Erro ao enviar APK', 'error');
    uploadBtn.disabled = false;
    uploadBtn.innerHTML = '<span class="material-icons-round">cloud_upload</span> Enviar APK';
    progressContainer.style.display = 'none';
  }
}

async function loadCurrentApkInfo() {
  const container = document.getElementById('current-apk-info');
  
  try {
    const response = await fetch(`${API_URL}/api/app-info`);
    const info = await response.json();
    
    if (info.available) {
      container.innerHTML = `
        <div class="apk-status available">
          <span class="material-icons-round" style="color: var(--success);">android</span>
          <div class="apk-details">
            <h4>CineFlow v${info.version.minVersion || '1.0.0'}</h4>
            <p>Tamanho: ${info.file.sizeFormatted} • Atualizado: ${formatDate(info.file.lastModified)}</p>
          </div>
          <a href="${API_URL}/download/app" class="btn-download" target="_blank">
            <span class="material-icons-round">download</span>
            Baixar
          </a>
        </div>
      `;
    } else {
      container.innerHTML = `
        <div class="apk-status">
          <span class="material-icons-round" style="color: var(--text-muted);">cloud_off</span>
          <div class="apk-details">
            <h4>Nenhum APK disponível</h4>
            <p>Faça upload de um APK acima para disponibilizar aos usuários.</p>
          </div>
        </div>
      `;
    }
  } catch (error) {
    console.error('Erro ao carregar info do APK:', error);
    container.innerHTML = '<p style="color: var(--text-muted);">Erro ao carregar informações</p>';
  }
}

document.getElementById('update-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const data = {
    minVersion: document.getElementById('min-version').value,
    forceUpdate: document.getElementById('force-update').checked,
    updateMessage: document.getElementById('update-message').value,
    downloadUrl: document.getElementById('download-url').value
  };
  
  try {
    const response = await fetch(`${API_URL}/api/admin/app-update`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });
    
    if (!response.ok) throw new Error('Erro ao salvar');
    
    showToast('Configurações salvas com sucesso', 'success');
  } catch (error) {
    console.error('Erro ao salvar:', error);
    showToast('Erro ao salvar configurações', 'error');
  }
});

// ============================================
// Configurações de Admin
// ============================================

document.getElementById('save-admins-btn').addEventListener('click', async () => {
  const emailsText = document.getElementById('admin-emails').value;
  const emails = emailsText.split('\n').map(e => e.trim()).filter(e => e);
  
  const masterKey = prompt('Digite a chave mestra para confirmar:');
  if (!masterKey) return;
  
  try {
    const response = await fetch(`${API_URL}/api/admin/set-admins`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ emails, masterKey })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error);
    }
    
    showToast('Administradores atualizados com sucesso', 'success');
  } catch (error) {
    console.error('Erro:', error);
    showToast(error.message || 'Erro ao salvar', 'error');
  }
});

// ============================================
// Utilitários
// ============================================

function formatDate(dateString) {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

function showToast(message, type = 'success') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <span class="material-icons-round">
      ${type === 'success' ? 'check_circle' : 'error'}
    </span>
    <span>${message}</span>
  `;
  container.appendChild(toast);
  
  setTimeout(() => {
    toast.remove();
  }, 4000);
}

// Verifica estado de autenticação
auth.onAuthStateChanged(async (user) => {
  if (user) {
    currentUser = user;
    authToken = await user.getIdToken();
    // Tenta ir para o dashboard
    try {
      const response = await fetch(`${API_URL}/api/admin/stats`, {
        headers: { 'Authorization': `Bearer ${authToken}` }
      });
      if (response.ok) {
        showDashboard();
      } else {
        showLogin();
      }
    } catch {
      showLogin();
    }
  } else {
    showLogin();
  }
});
