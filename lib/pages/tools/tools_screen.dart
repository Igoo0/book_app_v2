import 'package:flutter/material.dart';
import '../../services/currency_service.dart';
import '../../services/timezone_service.dart';
import '../../services/sensor_service.dart';
import '../../services/notification_service.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Changed to 4 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tools'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true, // Make tabs scrollable
          tabs: const [
            Tab(
              icon: Icon(Icons.currency_exchange),
              text: 'Currency',
            ),
            Tab(
              icon: Icon(Icons.schedule),
              text: 'Time Zones',
            ),
            Tab(
              icon: Icon(Icons.sensors),
              text: 'Sensors',
            ),
            // Tab(
            //   icon: Icon(Icons.notifications),
            //   text: 'Notifications',
            // ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CurrencyConverterTab(),
          TimeZoneConverterTab(),
          SensorInfoTab(),
          // NotificationTestTab(), // New tab
        ],
      ),
    );
  }
}

// // New Notification Test Tab
// class NotificationTestTab extends StatefulWidget {
//   const NotificationTestTab({super.key});

//   @override
//   State<NotificationTestTab> createState() => _NotificationTestTabState();
// }

// class _NotificationTestTabState extends State<NotificationTestTab> {
//   bool _isLoading = false;

//   Future<void> _showTestNotification(String type) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       switch (type) {
//         case 'welcome':
//           await NotificationService.instance.showWelcomeNotification(
//             username: 'Test User',
//           );
//           break;
//         case 'book_recommendation':
//           await NotificationService.instance.showBookRecommendationNotification(
//             bookTitle: 'The Great Gatsby',
//             author: 'F. Scott Fitzgerald',
//             bookId: 'test_book_123',
//           );
//           break;
//         case 'new_book':
//           await NotificationService.instance.showNewBookAlert(
//             bookTitle: 'Flutter in Action',
//             category: 'Programming',
//             bookId: 'flutter_book_456',
//           );
//           break;
//         case 'search_result':
//           await NotificationService.instance.showSearchResultNotification(
//             resultCount: 42,
//             query: 'science fiction',
//           );
//           break;
//         case 'favorite_added':
//           await NotificationService.instance.showFavoriteAddedNotification(
//             bookTitle: 'Dune',
//           );
//           break;
//         case 'daily_reminder':
//           await NotificationService.instance.showDailyReadingReminder();
//           break;
//         case 'currency_update':
//           await NotificationService.instance.showCurrencyUpdateNotification();
//           break;
//         case 'shake_detected':
//           await NotificationService.instance.showShakeDetectedNotification();
//           break;
//         case 'progress':
//           await NotificationService.instance.showProgressNotification(
//             title: 'Downloading Book',
//             body: 'Download in progress...',
//             progress: 75,
//             maxProgress: 100,
//           );
//           break;
//         case 'big_text':
//           await NotificationService.instance.showBigTextNotification(
//             title: 'Book Review',
//             shortBody: 'New review available',
//             longBody: 'This is a comprehensive review of the latest bestseller. The author has done an excellent job crafting characters and building a compelling narrative that keeps readers engaged from start to finish. The plot development is masterful and the writing style is both accessible and sophisticated.',
//           );
//           break;
//         case 'custom':
//           await NotificationService.instance.showNotification(
//             title: 'Custom Test Notification',
//             body: 'This is a custom notification for testing purposes!',
//             payload: 'custom_test',
//           );
//           break;
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('$type notification sent!'),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error sending notification: $e'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _requestPermissions() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await NotificationService.instance.requestPermissions();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Notification permissions requested!'),
//             backgroundColor: Colors.blue,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error requesting permissions: $e'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _scheduleWeeklyNotification() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await NotificationService.instance.scheduleWeeklyRecommendation();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Weekly notification scheduled!'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error scheduling notification: $e'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _cancelAllNotifications() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await NotificationService.instance.cancelAllNotifications();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('All notifications cancelled!'),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error cancelling notifications: $e'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Card(
//             elevation: 4,
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.notifications, color: Colors.indigo[800]),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Notification Testing',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.indigo[800],
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Test different types of notifications to ensure they work properly.',
//                     style: TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // Permission and control buttons
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: _isLoading ? null : _requestPermissions,
//                         icon: const Icon(Icons.security, size: 16),
//                         label: const Text('Request Permissions'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: _isLoading ? null : _scheduleWeeklyNotification,
//                         icon: const Icon(Icons.schedule, size: 16),
//                         label: const Text('Schedule Weekly'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: _isLoading ? null : _cancelAllNotifications,
//                         icon: const Icon(Icons.clear_all, size: 16),
//                         label: const Text('Cancel All'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Basic Notifications
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Basic Notifications',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.indigo[800],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationButton(
//                     'Welcome Notification',
//                     'Test welcome message for new users',
//                     Icons.waving_hand,
//                     Colors.green,
//                     () => _showTestNotification('welcome'),
//                   ),
//                   _buildNotificationButton(
//                     'Custom Notification',
//                     'Basic custom notification test',
//                     Icons.notification_add,
//                     Colors.blue,
//                     () => _showTestNotification('custom'),
//                   ),
//                   _buildNotificationButton(
//                     'Daily Reading Reminder',
//                     'Encourage users to read daily',
//                     Icons.menu_book,
//                     Colors.orange,
//                     () => _showTestNotification('daily_reminder'),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Book-Related Notifications
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Book-Related Notifications',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.indigo[800],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationButton(
//                     'Book Recommendation',
//                     'Suggest a new book to user',
//                     Icons.recommend,
//                     Colors.purple,
//                     () => _showTestNotification('book_recommendation'),
//                   ),
//                   _buildNotificationButton(
//                     'New Book Alert',
//                     'Notify about new releases',
//                     Icons.new_releases,
//                     Colors.red,
//                     () => _showTestNotification('new_book'),
//                   ),
//                   _buildNotificationButton(
//                     'Favorite Added',
//                     'Confirm book added to favorites',
//                     Icons.favorite,
//                     Colors.pink,
//                     () => _showTestNotification('favorite_added'),
//                   ),
//                   _buildNotificationButton(
//                     'Search Results',
//                     'Show search completion',
//                     Icons.search,
//                     Colors.teal,
//                     () => _showTestNotification('search_result'),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // App Feature Notifications
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'App Feature Notifications',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.indigo[800],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationButton(
//                     'Shake Detected',
//                     'Shake gesture recognition',
//                     Icons.vibration,
//                     Colors.amber,
//                     () => _showTestNotification('shake_detected'),
//                   ),
//                   _buildNotificationButton(
//                     'Currency Update',
//                     'Exchange rates updated',
//                     Icons.currency_exchange,
//                     Colors.indigo,
//                     () => _showTestNotification('currency_update'),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Advanced Notifications
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Advanced Notifications',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.indigo[800],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationButton(
//                     'Progress Notification',
//                     'Show download progress',
//                     Icons.download,
//                     Colors.cyan,
//                     () => _showTestNotification('progress'),
//                   ),
//                   _buildNotificationButton(
//                     'Big Text Notification',
//                     'Expandable text notification',
//                     Icons.text_fields,
//                     Colors.brown,
//                     () => _showTestNotification('big_text'),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Loading indicator
//           if (_isLoading)
//             const Center(
//               child: Column(
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 8),
//                   Text('Sending notification...'),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationButton(
//     String title,
//     String description,
//     IconData icon,
//     Color color,
//     VoidCallback onPressed,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 14,
//           ),
//         ),
//         subtitle: Text(
//           description,
//           style: const TextStyle(fontSize: 12),
//         ),
//         trailing: ElevatedButton(
//           onPressed: _isLoading ? null : onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: color,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             minimumSize: const Size(60, 30),
//           ),
//           child: const Text(
//             'Test',
//             style: TextStyle(fontSize: 12),
//           ),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       ),
//     );
//   }
// }

// // Keep the existing tabs as they were
class CurrencyConverterTab extends StatefulWidget {
  const CurrencyConverterTab({super.key});

  @override
  State<CurrencyConverterTab> createState() => _CurrencyConverterTabState();
}

class _CurrencyConverterTabState extends State<CurrencyConverterTab> {
  final TextEditingController _amountController = TextEditingController();

  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double _convertedAmount = 0.0;
  bool _isLoading = false;
  Map<String, double> _exchangeRates = {};

  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
    _amountController.text = '1';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rates = await CurrencyService.getExchangeRates();
      setState(() {
        _exchangeRates = rates;
        _isLoading = false;
      });
      _convertCurrency();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exchange rates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _convertCurrency() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    try {
      final result = await CurrencyService.convertCurrency(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        amount: amount,
      );

      setState(() {
        _convertedAmount = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversion error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convertCurrency();
  }

  @override
  Widget build(BuildContext context) {
    final currencies = CurrencyService.supportedCurrencies;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency converter card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.currency_exchange, color: Colors.indigo[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currency Converter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Amount input
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    onChanged: (value) => _convertCurrency(),
                  ),

                  const SizedBox(height: 16),

                  // From currency
                  DropdownButtonFormField<String>(
                    value: _fromCurrency,
                    decoration: InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    isExpanded: true,
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 25,
                              child: Text(
                                CurrencyService.getCurrencySymbol(currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$currency - ${CurrencyService.getCurrencyName(currency)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fromCurrency = value!;
                      });
                      _convertCurrency();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Swap button (centered)
                  Center(
                    child: IconButton(
                      onPressed: _swapCurrencies,
                      icon: const Icon(Icons.swap_vert),
                      iconSize: 32,
                      color: Colors.indigo[800],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // To currency
                  DropdownButtonFormField<String>(
                    value: _toCurrency,
                    decoration: InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    isExpanded: true,
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 25,
                              child: Text(
                                CurrencyService.getCurrencySymbol(currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$currency - ${CurrencyService.getCurrencyName(currency)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _toCurrency = value!;
                      });
                      _convertCurrency();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Result
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Converted Amount',
                          style: TextStyle(
                            color: Colors.indigo[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : FittedBox(
                                child: Text(
                                  CurrencyService.formatCurrency(
                                      _convertedAmount, _toCurrency),
                                  style: TextStyle(
                                    color: Colors.indigo[800],
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Refresh button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _loadExchangeRates,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Rates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Popular currencies
          if (_exchangeRates.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Exchange Rates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildPopularRates(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPopularRates() {
    final popular = ['EUR', 'GBP', 'JPY', 'IDR', 'SGD'];
    return popular.map((currency) {
      final rate = _exchangeRates[currency] ?? 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              child: Text(
                CurrencyService.getCurrencySymbol(currency),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 35,
              child: Text(
                currency,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '1 USD = ${rate.toStringAsFixed(2)} $currency',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class TimeZoneConverterTab extends StatefulWidget {
  const TimeZoneConverterTab({super.key});

  @override
  State<TimeZoneConverterTab> createState() => _TimeZoneConverterTabState();
}

class _TimeZoneConverterTabState extends State<TimeZoneConverterTab> {
  DateTime _selectedTime = DateTime.now();
  String _fromTimezone = 'WIB';
  String _toTimezone = 'LONDON';
  DateTime _convertedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _convertTime();
  }

  void _convertTime() {
    final converted = TimezoneService.convertTime(
      sourceTime: _selectedTime,
      fromTimezone: _fromTimezone,
      toTimezone: _toTimezone,
    );
    setState(() {
      _convertedTime = converted;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
      });
      _convertTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timezones = TimezoneService.supportedTimezones;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Time converter card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.indigo[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Time Zone Converter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Time picker
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              TimezoneService.formatDateTime(_selectedTime),
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // From timezone
                  DropdownButtonFormField<String>(
                    value: _fromTimezone,
                    decoration: InputDecoration(
                      labelText: 'From Timezone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    isExpanded: true,
                    items: timezones.map((timezone) {
                      return DropdownMenuItem(
                        value: timezone,
                        child: Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timezone,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fromTimezone = value!;
                      });
                      _convertTime();
                    },
                  ),

                  const SizedBox(height: 16),

                  // To timezone
                  DropdownButtonFormField<String>(
                    value: _toTimezone,
                    decoration: InputDecoration(
                      labelText: 'To Timezone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    isExpanded: true,
                    items: timezones.map((timezone) {
                      return DropdownMenuItem(
                        value: timezone,
                        child: Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timezone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _toTimezone = value!;
                      });
                      _convertTime();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Result
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Converted Time',
                          style: TextStyle(
                            color: Colors.indigo[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          TimezoneService.formatTime(_convertedTime),
                          style: TextStyle(
                            color: Colors.indigo[800],
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          TimezoneService.formatDateTime(_convertedTime),
                          style: TextStyle(
                            color: Colors.indigo[600],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // World clock
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'World Clock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...TimezoneService.getTimezoneList().map((tz) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tz['code'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  tz['name'],
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tz['currentTime'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SensorInfoTab extends StatefulWidget {
  const SensorInfoTab({super.key});

  @override
  State<SensorInfoTab> createState() => _SensorInfoTabState();
}

class _SensorInfoTabState extends State<SensorInfoTab> {
  Map<String, dynamic> _sensorData = {};
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    SensorService.instance.stopAllSensors();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
    });

    SensorService.instance.startAllSensors();

    // Update sensor data every 100ms
    Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
      if (mounted && _isListening) {
        setState(() {
          _sensorData = SensorService.instance.getSensorData();
        });
      }
    });
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    SensorService.instance.stopAllSensors();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Sensor Monitoring',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch(
                    value: _isListening,
                    onChanged: (value) {
                      if (value) {
                        _startListening();
                      } else {
                        _stopListening();
                      }
                    },
                    activeColor: Colors.indigo[800],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Accelerometer
          if (_sensorData['accelerometer'] != null) ...[
            _buildSensorCard(
              'Accelerometer',
              'Measures device acceleration including gravity',
              Icons.speed,
              _sensorData['accelerometer'],
              ['x', 'y', 'z'],
              'm/s²',
            ),
            const SizedBox(height: 12),
          ],

          // Gyroscope
          if (_sensorData['gyroscope'] != null) ...[
            _buildSensorCard(
              'Gyroscope',
              'Measures device rotation rate',
              Icons.rotate_right,
              _sensorData['gyroscope'],
              ['x', 'y', 'z'],
              'rad/s',
            ),
            const SizedBox(height: 12),
          ],

          // User Accelerometer
          if (_sensorData['userAccelerometer'] != null) ...[
            _buildSensorCard(
              'User Accelerometer',
              'Measures acceleration without gravity',
              Icons.trending_up,
              _sensorData['userAccelerometer'],
              ['x', 'y', 'z'],
              'm/s²',
            ),
            const SizedBox(height: 12),
          ],

          // Device status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.indigo[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Device Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow(
                      'Orientation', _sensorData['orientation'] ?? 'Unknown'),
                  _buildStatusRow('Is Flat',
                      _sensorData['isFlat']?.toString() ?? 'Unknown'),
                  _buildStatusRow('Is Moving',
                      _sensorData['isMoving']?.toString() ?? 'Unknown'),
                  _buildStatusRow('Tilt Angle',
                      '${(_sensorData['tiltAngle'] ?? 0.0).toStringAsFixed(1)}°'),
                  _buildStatusRow('Rotation Rate',
                      '${(_sensorData['rotationRate'] ?? 0.0).toStringAsFixed(3)} rad/s'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.indigo[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'How to Use',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Shake your device to trigger random book suggestions\n'
                    '• Tilt your device to see orientation changes\n'
                    '• Move your device to see acceleration values\n'
                    '• Rotate your device to see gyroscope readings',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(
    String title,
    String description,
    IconData icon,
    Map<String, dynamic> data,
    List<String> axes,
    String unit,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ...axes.map((axis) {
              final value = data[axis] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$axis-axis:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${value.toStringAsFixed(3)} $unit',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}