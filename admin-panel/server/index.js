const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
require('dotenv').config();

const { admin, db, auth } = require('./firebase-admin');

const app = express();
const PORT = process.env.PORT || 3000;

// Pasta para uploads
const UPLOADS_DIR = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Configuração do Multer para arquivos grandes (300MB)
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOADS_DIR),
  filename: (req, file, cb) => {
    // Salva como app-latest.apk (sobrescreve versões anteriores)
    cb(null, 'app-latest.apk');
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 300 * 1024 * 1024 }, // 300MB max
  fileFilter: (req, file, cb) => {
    if (file.originalname.endsWith('.apk')) {
      cb(null, true);
    } else {
      cb(new Error('Apenas arquivos .apk são permitidos!'), false);
    }
  }
});

// Middlewares
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Servir arquivos estáticos do frontend
const publicPath = path.join(__dirname, '../public');
console.log('📂 Servindo arquivos estáticos de:', publicPath);

// Verifica se a pasta existe
if (fs.existsSync(publicPath)) {
  console.log('✅ Pasta public encontrada!');
  console.log('📄 Arquivos:', fs.readdirSync(publicPath));
} else {
  console.error('❌ Pasta public NÃO encontrada em:', publicPath);
  console.log('📂 Conteúdo de __dirname:', fs.readdirSync(__dirname));
  console.log('📂 Conteúdo de ../:', fs.readdirSync(path.join(__dirname, '../')));
}

app.use(express.static(publicPath));

// Rota raiz explícita para debug (caso o static falhe)
app.get('/', (req, res, next) => {
  const indexPath = path.join(publicPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    next(); // Passa para o próximo handler (404)
  }
});

// Lista de emails de administradores autorizados (via env ou Firestore)
let ADMIN_EMAILS = process.env.ADMIN_EMAILS 
  ? process.env.ADMIN_EMAILS.split(',').map(e => e.trim())
  : [];

// Middleware de autenticação admin
const authenticateAdmin = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }
  
  const token = authHeader.split('Bearer ')[1];
  
  try {
    const decodedToken = await auth.verifyIdToken(token);
    
    // Verifica se é admin
    if (!ADMIN_EMAILS.includes(decodedToken.email)) {
      return res.status(403).json({ error: 'Acesso negado. Você não é um administrador.' });
    }
    
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Erro de autenticação:', error);
    return res.status(401).json({ error: 'Token inválido' });
  }
};

// ==========================================
// ROTAS PÚBLICAS
// ==========================================

// Rota para servir o painel admin
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Verifica versão do app (usado pelo app Flutter)
app.get('/api/app-version', async (req, res) => {
  try {
    const configDoc = await db.collection('app_config').doc('version').get();
    
    if (!configDoc.exists) {
      return res.json({
        minVersion: '1.0.0',
        forceUpdate: false,
        updateMessage: '',
        downloadUrl: ''
      });
    }
    
    res.json(configDoc.data());
  } catch (error) {
    console.error('Erro ao buscar versão:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Verifica se usuário está bloqueado (usado pelo app Flutter)
app.get('/api/user/:uid/status', async (req, res) => {
  try {
    const { uid } = req.params;
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      return res.json({ isBlocked: false });
    }
    
    const userData = userDoc.data();
    res.json({ 
      isBlocked: userData.isBlocked || false,
      blockedReason: userData.blockedReason || ''
    });
  } catch (error) {
    console.error('Erro ao verificar status:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Download do APK (público)
app.get('/download/app', (req, res) => {
  const apkPath = path.join(UPLOADS_DIR, 'app-latest.apk');
  
  if (!fs.existsSync(apkPath)) {
    return res.status(404).json({ error: 'APK não disponível ainda' });
  }
  
  const stat = fs.statSync(apkPath);
  res.setHeader('Content-Length', stat.size);
  res.setHeader('Content-Type', 'application/vnd.android.package-archive');
  res.setHeader('Content-Disposition', 'attachment; filename=CineFlow.apk');
  
  const readStream = fs.createReadStream(apkPath);
  readStream.pipe(res);
});

// Info do APK atual
app.get('/api/app-info', async (req, res) => {
  const apkPath = path.join(UPLOADS_DIR, 'app-latest.apk');
  const exists = fs.existsSync(apkPath);
  
  let fileInfo = null;
  if (exists) {
    const stat = fs.statSync(apkPath);
    fileInfo = {
      size: stat.size,
      sizeFormatted: (stat.size / (1024 * 1024)).toFixed(2) + ' MB',
      lastModified: stat.mtime
    };
  }
  
  try {
    const configDoc = await db.collection('app_config').doc('version').get();
    const versionInfo = configDoc.exists ? configDoc.data() : {};
    
    res.json({
      available: exists,
      file: fileInfo,
      version: versionInfo
    });
  } catch (error) {
    res.json({ available: exists, file: fileInfo, version: {} });
  }
});

// ==========================================
// ROTAS DE CONTEÚDO (M3U)
// ==========================================

// Pasta de dados
const DATA_DIR = path.join(__dirname, 'data');
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Verifica versão do conteúdo
app.get('/api/content/version', (req, res) => {
  try {
    const versionPath = path.join(DATA_DIR, 'content-version.json');
    
    if (!fs.existsSync(versionPath)) {
      return res.json({ 
        version: '0',
        updatedAt: null,
        description: 'Nenhuma versão disponível'
      });
    }
    
    const versionData = JSON.parse(fs.readFileSync(versionPath, 'utf8'));
    res.json(versionData);
  } catch (error) {
    console.error('Erro ao ler versão do conteúdo:', error);
    res.status(500).json({ error: 'Erro ao verificar versão' });
  }
});

// Baixa o arquivo M3U
app.get('/api/content/m3u', (req, res) => {
  try {
    const m3uPath = path.join(DATA_DIR, 'canais.m3u');
    
    if (!fs.existsSync(m3uPath)) {
      console.log('⚠️ Arquivo canais.m3u não encontrado em:', m3uPath);
      return res.status(404).json({ 
        error: 'Arquivo de canais não disponível',
        hint: 'Faça upload do canais.m3u para a pasta data/'
      });
    }
    
    const stat = fs.statSync(m3uPath);
    console.log(`📺 Servindo canais.m3u (${(stat.size / 1024 / 1024).toFixed(2)} MB)`);
    
    res.setHeader('Content-Type', 'audio/x-mpegurl');
    res.setHeader('Content-Length', stat.size);
    res.setHeader('Cache-Control', 'no-cache');
    
    const readStream = fs.createReadStream(m3uPath);
    readStream.pipe(res);
  } catch (error) {
    console.error('Erro ao servir M3U:', error);
    res.status(500).json({ error: 'Erro ao carregar conteúdo' });
  }
});

// Info do conteúdo
app.get('/api/content/info', (req, res) => {
  try {
    const m3uPath = path.join(DATA_DIR, 'canais.m3u');
    const versionPath = path.join(DATA_DIR, 'content-version.json');
    
    const m3uExists = fs.existsSync(m3uPath);
    let fileInfo = null;
    let versionInfo = null;
    
    if (m3uExists) {
      const stat = fs.statSync(m3uPath);
      fileInfo = {
        size: stat.size,
        sizeFormatted: (stat.size / (1024 * 1024)).toFixed(2) + ' MB',
        lastModified: stat.mtime
      };
    }
    
    if (fs.existsSync(versionPath)) {
      versionInfo = JSON.parse(fs.readFileSync(versionPath, 'utf8'));
    }
    
    res.json({
      available: m3uExists,
      file: fileInfo,
      version: versionInfo
    });
  } catch (error) {
    console.error('Erro ao verificar conteúdo:', error);
    res.status(500).json({ error: 'Erro ao verificar conteúdo' });
  }
});

// ==========================================
// ROTAS ADMIN (PROTEGIDAS)
// ==========================================

// Configurar admins (temporário - depois mover para config)
app.post('/api/admin/set-admins', async (req, res) => {
  const { emails, masterKey } = req.body;
  
  // Chave mestra para configuração inicial
  if (masterKey !== process.env.ADMIN_MASTER_KEY && masterKey !== 'cineflow-admin-2024') {
    return res.status(403).json({ error: 'Chave mestra inválida' });
  }
  
  ADMIN_EMAILS = emails;
  
  // Salva no Firestore
  await db.collection('app_config').doc('admins').set({
    emails: emails,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  res.json({ success: true, admins: ADMIN_EMAILS });
});

// Lista todos os usuários
app.get('/api/admin/users', authenticateAdmin, async (req, res) => {
  try {
    // Busca usuários do Firebase Auth
    const listUsersResult = await auth.listUsers(1000);
    
    // Busca dados extras do Firestore
    const usersSnapshot = await db.collection('users').get();
    const firestoreUsers = {};
    usersSnapshot.forEach(doc => {
      firestoreUsers[doc.id] = doc.data();
    });
    
    const users = listUsersResult.users.map(user => {
      const extraData = firestoreUsers[user.uid] || {};
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName || extraData.displayName || 'Sem nome',
        photoURL: user.photoURL,
        createdAt: user.metadata.creationTime,
        lastSignIn: user.metadata.lastSignInTime,
        isBlocked: extraData.isBlocked || false,
        blockedReason: extraData.blockedReason || '',
        blockedAt: extraData.blockedAt || null
      };
    });
    
    res.json({ users, total: users.length });
  } catch (error) {
    console.error('Erro ao listar usuários:', error);
    res.status(500).json({ error: 'Erro ao listar usuários' });
  }
});

// Bloqueia/Desbloqueia usuário
app.put('/api/admin/users/:uid/block', authenticateAdmin, async (req, res) => {
  try {
    const { uid } = req.params;
    const { block, reason } = req.body;
    
    // Atualiza no Firestore
    await db.collection('users').doc(uid).set({
      isBlocked: block,
      blockedReason: block ? (reason || 'Bloqueado pelo administrador') : '',
      blockedAt: block ? admin.firestore.FieldValue.serverTimestamp() : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    // Log de auditoria
    await db.collection('admin_logs').add({
      action: block ? 'BLOCK_USER' : 'UNBLOCK_USER',
      targetUid: uid,
      adminEmail: req.user.email,
      reason: reason || '',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    res.json({ 
      success: true, 
      message: block ? 'Usuário bloqueado' : 'Usuário desbloqueado' 
    });
  } catch (error) {
    console.error('Erro ao bloquear usuário:', error);
    res.status(500).json({ error: 'Erro ao atualizar usuário' });
  }
});

// Define versão mínima do app
app.post('/api/admin/app-update', authenticateAdmin, async (req, res) => {
  try {
    const { minVersion, forceUpdate, updateMessage, downloadUrl } = req.body;
    
    await db.collection('app_config').doc('version').set({
      minVersion: minVersion || '1.0.0',
      forceUpdate: forceUpdate || false,
      updateMessage: updateMessage || 'Uma nova versão está disponível!',
      downloadUrl: downloadUrl || '',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: req.user.email
    });
    
    // Log de auditoria
    await db.collection('admin_logs').add({
      action: 'UPDATE_APP_VERSION',
      data: { minVersion, forceUpdate },
      adminEmail: req.user.email,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    res.json({ success: true, message: 'Versão atualizada com sucesso' });
  } catch (error) {
    console.error('Erro ao atualizar versão:', error);
    res.status(500).json({ error: 'Erro ao atualizar versão' });
  }
});

// Upload de APK
app.post('/api/admin/upload-apk', authenticateAdmin, upload.single('apk'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhum arquivo enviado' });
    }
    
    const { version } = req.body;
    const fileSize = req.file.size;
    const fileSizeFormatted = (fileSize / (1024 * 1024)).toFixed(2) + ' MB';
    
    // Atualiza informações no Firestore
    // Gera URL de download correta
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers['x-forwarded-host'] || req.get('host');
    const baseUrl = `${protocol}://${host}`;
    
    // Se estiver no Railway, força HTTPS
    const downloadUrl = process.env.RAILWAY_PUBLIC_DOMAIN 
      ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}/download/app`
      : `${baseUrl}/download/app`;
    
    await db.collection('app_config').doc('version').set({
      minVersion: version || '1.0.0',
      forceUpdate: true,
      updateMessage: 'Nova versão disponível! Atualize agora.',
      downloadUrl: downloadUrl,
      fileSize: fileSize,
      fileSizeFormatted: fileSizeFormatted,
      uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
      uploadedBy: req.user.email
    }, { merge: true });
    
    // Log de auditoria
    await db.collection('admin_logs').add({
      action: 'UPLOAD_APK',
      data: { version, fileSize: fileSizeFormatted },
      adminEmail: req.user.email,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`📦 APK uploaded: ${fileSizeFormatted} by ${req.user.email}`);
    
    res.json({ 
      success: true, 
      message: 'APK enviado com sucesso!',
      file: {
        size: fileSize,
        sizeFormatted: fileSizeFormatted,
        downloadUrl: downloadUrl
      }
    });
  } catch (error) {
    console.error('Erro ao fazer upload:', error);
    res.status(500).json({ error: 'Erro ao fazer upload do APK' });
  }
});

// Upload de Conteúdo (M3U)
app.post('/api/admin/upload-content', authenticateAdmin, upload.single('m3u'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhum arquivo enviado' });
    }
    
    // Move o arquivo para a pasta data
    const tempPath = req.file.path;
    const targetPath = path.join(DATA_DIR, 'canais.m3u');
    
    // Usa copy + unlink em vez de rename para evitar erro EXDEV (cross-device link)
    fs.copyFileSync(tempPath, targetPath);
    fs.unlinkSync(tempPath);
    
    const fileSize = req.file.size;
    const fileSizeFormatted = (fileSize / (1024 * 1024)).toFixed(2) + ' MB';
    
    // Atualiza versão do conteúdo
    const now = new Date();
    const versionStr = `${now.getFullYear()}.${(now.getMonth() + 1).toString().padStart(2, '0')}.${now.getDate().toString().padStart(2, '0')}.${now.getHours()}${now.getMinutes()}`;
    
    const versionData = {
      version: versionStr,
      updatedAt: now.toISOString(),
      description: req.body.description || 'Atualização de conteúdo',
      size: fileSizeFormatted
    };
    
    fs.writeFileSync(path.join(DATA_DIR, 'content-version.json'), JSON.stringify(versionData, null, 2));
    
    // Log de auditoria
    await db.collection('admin_logs').add({
      action: 'UPLOAD_CONTENT',
      data: { version: versionStr, size: fileSizeFormatted },
      adminEmail: req.user.email,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`📺 Content uploaded: ${fileSizeFormatted} (v${versionStr}) by ${req.user.email}`);
    
    res.json({ 
      success: true, 
      message: 'Conteúdo atualizado com sucesso!',
      version: versionData
    });
  } catch (error) {
    console.error('Erro ao fazer upload de conteúdo:', error);
    res.status(500).json({ error: 'Erro ao fazer upload de conteúdo' });
  }
});

// Estatísticas gerais
app.get('/api/admin/stats', authenticateAdmin, async (req, res) => {
  try {
    const [usersResult, blockedSnapshot] = await Promise.all([
      auth.listUsers(1000),
      db.collection('users').where('isBlocked', '==', true).get()
    ]);
    
    const totalUsers = usersResult.users.length;
    const blockedUsers = blockedSnapshot.size;
    
    // Usuários dos últimos 7 dias
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    
    const recentUsers = usersResult.users.filter(u => 
      new Date(u.metadata.creationTime) > weekAgo
    ).length;
    
    res.json({
      totalUsers,
      blockedUsers,
      activeUsers: totalUsers - blockedUsers,
      recentUsers
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas:', error);
    res.status(500).json({ error: 'Erro ao buscar estatísticas' });
  }
});

// Carrega admins do Firestore na inicialização
async function loadAdmins() {
  try {
    const adminsDoc = await db.collection('app_config').doc('admins').get();
    if (adminsDoc.exists) {
      ADMIN_EMAILS = adminsDoc.data().emails || [];
      console.log('📋 Admins carregados:', ADMIN_EMAILS);
    }
  } catch (error) {
    console.log('⚠️  Nenhum admin configurado ainda');
  }
}

// Inicializa o servidor
loadAdmins().then(() => {
  app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║   🎬 CineFlow Admin Panel Server                      ║
║                                                       ║
║   Servidor rodando em: http://localhost:${PORT}          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
    `);
  });
});
