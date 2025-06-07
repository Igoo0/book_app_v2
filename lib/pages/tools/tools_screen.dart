import 'package:flutter/material.dart';
import '../../services/currency_service.dart';
import '../../services/timezone_service.dart';
import '../../services/sensor_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CurrencyConverterTab(),
          TimeZoneConverterTab(),
          SensorInfoTab(),
        ],
      ),
    );
  }
}

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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timezone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                TimezoneService.getTimezoneName(timezone),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timezone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                TimezoneService.getTimezoneName(timezone),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
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