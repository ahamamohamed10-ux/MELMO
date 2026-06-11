import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class MpesaService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Déclenche un STK Push M-Pesa Daraja
  /// [phoneNumber] doit être au format international sans le + (ex: 254712345678)
  /// [amount] le montant en KES
  Future<Map<String, dynamic>> initierPaiement({
    required String phoneNumber,
    required int amount,
  }) async {
    try {
      // Appel de la fonction Cloud "triggerMpesaStkPush" v2 déjá déployée
      HttpsCallable callable = _functions.httpsCallable('triggerMpesaStkPush');
      
      final response = await callable.call(<String, dynamic>{
        'phoneNumber': phoneNumber,
        'amount': amount,
      });

      // Récupération des données renvoyées par le serveur
      final result = Map<String, dynamic>.from(response.data as Map);
      
      if (result['success'] == true) {
        debugPrint("STK Push envoyé avec succès : ${result['data']}");
        return {
          'success': true,
          'message': 'Demande de paiement envoyée sur le téléphone !',
          'data': result['data']
        };
      } else {
        return {
          'success': false,
          'message': 'Échec de l\'initialisation du paiement.',
        };
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint("Erreur Firebase Functions: [${e.code}] - ${e.message}");
      return {
        'success': false,
        'message': 'Erreur serveur : ${e.message}',
      };
    } catch (e) {
      debugPrint("Erreur inconnue M-Pesa Service: $e");
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue.',
      };
    }
  }
}