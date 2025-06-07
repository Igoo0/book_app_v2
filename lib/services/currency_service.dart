 import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://api.freecurrencyapi.com/v1/latest';
  static const String _apiKey = 'fca_live_j5bOeG3N77j51CJEt3yPqer09NxCZerYzxFcXy40'; // Replace with actual API key

  static const Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'IDR': 'Indonesian Rupiah',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'THB': 'Thai Baht',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'KRW': 'South Korean Won',
    'HKD': 'Hong Kong Dollar',
  };

  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'IDR': 'Rp',
    'SGD': 'S\$',
    'MYR': 'RM',
    'THB': '฿',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'INR': '₹',
    'KRW': '₩',
    'HKD': 'HK\$',
  };

  static List<String> get supportedCurrencies => _currencyNames.keys.toList();

  static String getCurrencyName(String code) {
    return _currencyNames[code] ?? code;
  }

  static String getCurrencySymbol(String code) {
    return _currencySymbols[code] ?? code;
  }

  static Future<Map<String, double>> getExchangeRates({String baseCurrency = 'USD'}) async {
    try {
      if (_apiKey.isEmpty) {
        // Return mock data if API key is not set
        return _getMockExchangeRates(baseCurrency);
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'apikey': _apiKey,
        'base_currency': baseCurrency,
        'currencies': supportedCurrencies.join(','),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['data'] as Map<String, dynamic>;
        
        return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        throw Exception('Failed to load exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data as fallback
      return _getMockExchangeRates(baseCurrency);
    }
  }

  static Future<double> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    try {
      if (fromCurrency == toCurrency) return amount;

      // Get exchange rates with USD as base
      final rates = await getExchangeRates(baseCurrency: 'USD');
      
      double fromRate = rates[fromCurrency] ?? 1.0;
      double toRate = rates[toCurrency] ?? 1.0;
      
      // If fromCurrency is not USD, convert to USD first
      if (fromCurrency != 'USD') {
        amount = amount / fromRate;
      }
      
      // Convert from USD to target currency
      if (toCurrency != 'USD') {
        amount = amount * toRate;
      }
      
      return amount;
    } catch (e) {
      throw Exception('Currency conversion failed: $e');
    }
  }

  static String formatCurrency(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    
    // Format with appropriate decimal places
    if (currencyCode == 'JPY' || currencyCode == 'KRW' || currencyCode == 'IDR') {
      // Currencies that don't use decimals
      return '$symbol${amount.round()}';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  static Map<String, double> _getMockExchangeRates(String baseCurrency) {
    // Mock exchange rates for development/fallback
    final Map<String, double> usdRates = {
      'USD': 1.0,
      'EUR': 0.85,
      'GBP': 0.73,
      'JPY': 110.0,
      'IDR': 14500.0,
      'SGD': 1.35,
      'MYR': 4.2,
      'THB': 33.0,
      'CAD': 1.25,
      'AUD': 1.35,
      'CHF': 0.92,
      'CNY': 6.45,
      'INR': 75.0,
      'KRW': 1180.0,
      'HKD': 7.8,
    };

    if (baseCurrency == 'USD') {
      return usdRates;
    }

    // Convert rates to different base currency
    final baseRate = usdRates[baseCurrency] ?? 1.0;
    return usdRates.map((key, value) => MapEntry(key, value / baseRate));
  }

  static List<Map<String, String>> getCurrencyList() {
    return supportedCurrencies.map((code) => {
      'code': code,
      'name': getCurrencyName(code),
      'symbol': getCurrencySymbol(code),
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getPopularCurrencies() async {
    final popularCodes = ['USD', 'EUR', 'GBP', 'JPY', 'IDR'];
    final rates = await getExchangeRates();
    
    return popularCodes.map((code) => {
      'code': code,
      'name': getCurrencyName(code),
      'symbol': getCurrencySymbol(code),
      'rate': rates[code] ?? 1.0,
    }).toList();
  }
}
