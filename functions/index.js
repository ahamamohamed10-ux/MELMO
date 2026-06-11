const { onCall, HttpsError } = require("firebase-functions/v2/https");
const axios = require("axios");

// Vos identifiants Daraja (M-Pesa Sandbox)
const CONSUMER_KEY = "AWUGXBTKAL3mGcA6QwgA3QoBeTnkSs8EQCc0GA4hhnoRr7NE";
const CONSUMER_SECRET = "rmaetSTpnEK4XBSW4Ohf2SfP7eIEAGYAVwi5muCrthtaLIHDwAI8Nu9QMUN8fxjP";

exports.triggerMpesaStkPush = onCall({ cors: true }, async (request) => {
  // En v2, les données envoyées par Flutter se trouvent dans request.data
  const rawPhoneNumber = request.data.phoneNumber; // Récupération brute
  const amount = request.data.amount;             // Montant

  if (!rawPhoneNumber || !amount) {
    throw new HttpsError("invalid-argument", "Le numéro et le montant sont requis.");
  }

  // 🧹 NETTOYAGE ET FORMATAGE DU NUMÉRO DE TÉLÉPHONE
  let phoneNumber = rawPhoneNumber.replace(/[^0-9]/g, ""); // Enlève les "+" ou espaces

  if (phoneNumber.startsWith("0")) {
    // Si le numéro commence par 07... ou 01..., on remplace le 0 par 254
    phoneNumber = "254" + phoneNumber.substring(1);
  } else if (phoneNumber.startsWith("7") || phoneNumber.startsWith("1")) {
    // Si l'utilisateur a écrit directement 7... ou 1..., on ajoute 254 devant
    phoneNumber = "254" + phoneNumber;
  }

  try {
    // 1. Génération du Token OAuth
    const auth = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString("base64");
    const tokenResponse = await axios.get(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      { headers: { Authorization: `Basic ${auth}` } }
    );
    const accessToken = tokenResponse.data.access_token;

    // 2. Préparation du Timestamp à l'heure locale du Kenya (EAT - UTC+3)
    const now = new Date();
    const options = { 
      timeZone: 'Africa/Nairobi', 
      year: 'numeric', 
      month: '2-digit', 
      day: '2-digit', 
      hour: '2-digit', 
      minute: '2-digit', 
      second: '2-digit', 
      hour12: false 
    };
    
    const formatter = new Intl.DateTimeFormat('en-US', options);
    const parts = formatter.formatToParts(now);
    const dateObj = Object.fromEntries(parts.map(p => [p.type, p.value]));
    
    // Format requis par Safaricom : YYYYMMDDHHMMSS
    const timestamp = `${dateObj.year}${dateObj.month}${dateObj.day}${dateObj.hour}${dateObj.minute}${dateObj.second}`;

    // 3. Génération du Password requis pour le STK Push
    const businessShortCode = "174379"; 
    const passkey = "bfb272f96307a314ebe1a09138d8d366c745b66b26f70164d6533e2b1b861192";
    const password = Buffer.from(`${businessShortCode}${passkey}${timestamp}`).toString("base64");

    // 4. Envoi de la requête STK Push à Safaricom
    const stkPushResponse = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      {
        "BusinessShortCode": businessShortCode,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": Math.round(amount), // Assure un montant entier (ex: 1)
        "PartyA": phoneNumber, 
        "PartyB": businessShortCode,
        "PhoneNumber": phoneNumber, 
        "CallBackURL": "https://mydomain.com/callback", 
        "AccountReference": "MELMO_Store",
        "TransactionDesc": "Paiement de test e-commerce"
      },
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );

    return { success: true, data: stkPushResponse.data };

  } catch (error) {
    console.error("Erreur M-Pesa:", error.response ? error.response.data : error.message);
    throw new HttpsError("internal", "Échec du traitement du paiement M-Pesa.");
  }
});