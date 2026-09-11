import 'package:flutter/material.dart';

class DeliveryInfoTile extends StatelessWidget {
  final double shippingFee;
  final String estimatedDelivery;
  final String destinationName;
  final String currencySymbol;
  final int returnPolicyDays;

  const DeliveryInfoTile({
    super.key,
    this.shippingFee = 0.0,
    this.estimatedDelivery = '2 - 4 jours',
    this.destinationName = 'AUX COMORES',
    this.currencySymbol = '€',
    this.returnPolicyDays = 14,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFree = shippingFee <= 0.0;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Formatting shipping fee with 2 decimals if non-zero fractional part exists
    final String formattedFee = shippingFee % 1 == 0
        ? shippingFee.toStringAsFixed(0)
        : shippingFee.toStringAsFixed(2);

    final String dayLabel = returnPolicyDays == 1 ? 'jour' : 'jours';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFFD4AF37),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Livraison $destinationName",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Estimée à $estimatedDelivery",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isFree ? "GRATUITE" : "$formattedFee $currencySymbol",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isFree
                      ? (isDarkMode ? Colors.green[400] : Colors.green[700])
                      : const Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Politique de retour sous $returnPolicyDays $dayLabel",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}