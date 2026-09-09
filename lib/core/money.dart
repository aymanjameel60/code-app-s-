// Cart, quote and order line amounts are stored in USD on the backend; the
// display currency is resolved with /currencies rate_from_usd at render time.
String formatMoney(double usdAmount, {required String code, double rate = 1}) {
  final value = usdAmount * rate;
  final c = code.trim().toUpperCase();
  if (c == 'USD') return '\$${value.toStringAsFixed(2)}';
  if (c == 'SAR') return '${value.toStringAsFixed(2)} ر.س';
  if (c == 'YER_OLD' || c == 'YER') return '${value.round()} ر.ي';
  if (c == 'TRY') return '${value.toStringAsFixed(2)} ₺';
  return '${value.toStringAsFixed(2)} $c';
}
