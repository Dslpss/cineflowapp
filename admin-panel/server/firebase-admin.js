const admin = require('firebase-admin');
const path = require('path');

// Inicializa o Firebase Admin SDK
// Suporta: variável de ambiente FIREBASE_CONFIG ou arquivo serviceAccountKey.json

let serviceAccount;

// Tenta carregar das variáveis de ambiente primeiro (Railway)
if (process.env.FIREBASE_CONFIG) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_CONFIG);
    console.log('✅ Firebase config carregado das variáveis de ambiente');
  } catch (e) {
    console.error('❌ Erro ao parsear FIREBASE_CONFIG:', e.message);
  }
}

// Se não tiver na env, tenta carregar do arquivo local
if (!serviceAccount) {
  const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
  try {
    serviceAccount = require(serviceAccountPath);
    console.log('✅ Firebase config carregado do arquivo local');
  } catch (e) {
    console.error('❌ Arquivo serviceAccountKey.json não encontrado');
    console.log('⚠️  Configure a variável FIREBASE_CONFIG ou adicione o arquivo');
  }
}

// Inicializa apenas se tiver as credenciais
if (serviceAccount) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`
    });
    console.log('✅ Firebase Admin SDK inicializado com sucesso');
  } catch (error) {
    console.error('❌ Erro ao inicializar Firebase Admin:', error.message);
  }
} else {
  console.error('❌ Firebase Admin NÃO inicializado - faltam credenciais');
}

const db = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
