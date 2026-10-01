const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

// Initialisation sécurisée de Firebase Admin
if (!admin.apps || admin.apps.length === 0) {
  admin.initializeApp();
}

// CONFIGURATION MVOLA
const MVOLA_CONFIG = {
  baseUrl: process.env.MVOLA_BASE_URL || "https://sandbox.mvola.mg",
  consumerKey: process.env.MVOLA_CONSUMER_KEY || "VOTRE_CONSUMER_KEY_SANDBOX",
  consumerSecret: process.env.MVOLA_CONSUMER_SECRET || "VOTRE_CONSUMER_SECRET_SANDBOX",
  merchantMsisdn: process.env.MVOLA_MERCHANT_MSISDN || "0343500003",
  companyName: "MoMart Store",
  callbackUrl: "https://mvolacallback-rehs2bwcsa-uc.a.run.app",
  
};

/**
 * 1. Génération du jeton d'accès OAuth 2.0
 */
async function getMvolaAccessToken() {
  const axios = require("axios");
  const credentials = Buffer.from(
    `${MVOLA_CONFIG.consumerKey}:${MVOLA_CONFIG.consumerSecret}`
  ).toString("base64");

  try {
    const response = await axios.post(
      `${MVOLA_CONFIG.baseUrl}/token`,
      "grant_type=client_credentials&scope=EXT_INT_MVOLA_SCOPE",
      {
        headers: {
          "Authorization": `Basic ${credentials}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        timeout: 10000,
      }
    );
    return response.data.access_token;
  } catch (error) {
    logger.error("Erreur Token MVola:", error.response?.data || error.message);
    throw new HttpsError("internal", "Impossible de générer le jeton de sécurité MVola.");
  }
}

/**
 * 2. Cloud Function Callable pour initier le paiement MVola depuis Flutter
 */
exports.mvolaPay = onCall({ cors: true }, async (request) => {
  const { v4: uuidv4 } = require("uuid");
  const axios = require("axios");

  const { phoneNumber, amount, description } = request.data;

  if (!phoneNumber || !amount) {
    throw new HttpsError(
      "invalid-argument",
      "Le numéro de téléphone et le montant sont requis."
    );
  }

  let formattedPhone = phoneNumber.replace(/\D/g, "");
  if (formattedPhone.startsWith("261")) {
    formattedPhone = "0" + formattedPhone.substring(3);
  }

  try {
    const accessToken = await getMvolaAccessToken();
    const clientCorrelationId = uuidv4();
    const transactionRef = `TX-${Date.now()}`;

    const payload = {
      amount: amount.toString(),
      currency: "Ar",
      descriptionText: description || "Paiement commande MoMart",
      requestDate: new Date().toISOString(),
      debitParty: [{ key: "msisdn", value: formattedPhone }],
      creditParty: [{ key: "msisdn", value: MVOLA_CONFIG.merchantMsisdn }],
      metadata: [
        { key: "partnerName", value: MVOLA_CONFIG.companyName },
        { key: "fcTransactionRef", value: transactionRef },
      ],
    };

    const headers = {
      "Authorization": `Bearer ${accessToken}`,
      "Version": "1.0",
      "X-CorrelationID": clientCorrelationId,
      "UserLanguage": "FR",
      "UserAccountIdentifier": MVOLA_CONFIG.merchantMsisdn,
      "Content-Type": "application/json",
      "Cache-Control": "no-cache",
      "X-Callback-URL": MVOLA_CONFIG.callbackUrl,
    };

    const response = await axios.post(
      `${MVOLA_CONFIG.baseUrl}/mvola/mm/transactions/type/m0/1.0.0/`,
      payload,
      { headers, timeout: 15000 }
    );

    const resData = response.data;

    await admin.firestore().collection("mvola_transactions").doc(clientCorrelationId).set({
      transactionRef: transactionRef,
      serverCorrelationId: resData.serverCorrelationId || null,
      status: resData.status || "pending",
      amount: amount,
      phoneNumber: formattedPhone,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      status: resData.status,
      serverCorrelationId: resData.serverCorrelationId,
      clientCorrelationId: clientCorrelationId,
      message: "Demande de paiement MVola transmise avec succès.",
    };
  } catch (error) {
    logger.error("Erreur MVola Pay API:", error.response?.data || error.message);
    return {
      success: false,
      message: error.response?.data?.message || "Échec de l'initialisation du paiement MVola.",
    };
  }
});

/**
 * 3. Webhook Callback pour recevoir la confirmation de transaction envoyée par MVola
 */
exports.mvolaCallback = onRequest(async (req, res) => {
  try {
    const callbackData = req.body;
    const correlationId = req.headers["x-correlationid"] || callbackData.serverCorrelationId;

    logger.info("Notification MVola reçue :", callbackData);

    if (correlationId) {
      const query = await admin
        .firestore()
        .collection("orders")
        .where("transactionReference", "==", correlationId)
        .get();

      if (!query.empty) {
        const orderDoc = query.docs[0];
        await orderDoc.ref.update({
          status: callbackData.status === "completed" ? "Payé" : "Échoué",
          mvolaTransactionDetails: callbackData,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    res.status(200).send({ status: "RECEIVED" });
  } catch (err) {
    logger.error("Erreur traitement Webhook MVola:", err);
    res.status(500).send("Internal Server Error");
  }
});