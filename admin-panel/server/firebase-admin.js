const admin = require('firebase-admin');
const path = require('path');

// Inicializa o Firebase Admin SDK
// IMPORTANTE: O arquivo serviceAccountKey.json deve ser gerado no Firebase Console
// Project Settings -> Service Accounts -> Generate new private key
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 
  path.join(__dirname, 'serviceAccountKey.json');

try {
  const serviceAccount = require(serviceAccountPath);
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`
  });
  
  console.log('✅ Firebase Admin SDK inicializado com sucesso');
} catch (error) {
  console.error('❌ Erro ao inicializar Firebase Admin:', error.message);
  console.log('⚠️  Verifique se o arquivo serviceAccountKey.json existe em:', serviceAccountPath);
}

const db = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
