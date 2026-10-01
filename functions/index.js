const admin = require("firebase-admin");

if (!admin.apps || admin.apps.length === 0) {
  admin.initializeApp();
}