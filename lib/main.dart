import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  // Setup a formatter that supports both commas for thousands and decimals
  final formatter = NumberFormat("#,##0.###");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    // Remove commas to check the new input and for parsing
    final newText = newValue.text.replaceAll(',', '');
    // Try parsing the input as a double
    final num? newTextAsNum = num.tryParse(newText);

    if (newTextAsNum == null) {
      return oldValue; // Return old value if new value is not a number
    }

    // Split the input into whole number and decimal parts
    final parts = newText.split('.');
    if (parts.length > 1) {
      // If there's a decimal part, format accordingly
      final integerPart = int.tryParse(parts[0]) ?? 0;
      final decimalPart = parts[1];
      // Handle edge case where decimal part is present but empty (user just typed the dot)
      final formattedText = '${formatter.format(integerPart)}.$decimalPart';
      return TextEditingValue(
        text: formattedText,
        selection: updateCursorPosition(formattedText),
      );
    } else {
      // No decimal part, format the whole number
      final newFormattedText = formatter.format(newTextAsNum);
      return TextEditingValue(
        text: newFormattedText,
        selection: updateCursorPosition(newFormattedText),
      );
    }
  }

  TextSelection updateCursorPosition(String text) {
    return TextSelection.collapsed(offset: text.length);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Form Example',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: Color(0xFF1877F2), // Exact Facebook Blue
            secondary: Color(0xFF1877F2),
          ),
        ),
        home: const MyFormPage(),
      ),
    );
  }
}

class MyFormPage extends StatefulWidget {
  const MyFormPage({super.key});

  @override
  State<MyFormPage> createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _revenueController = TextEditingController();

  double? _sliderValue;
  double _maxSliderValue = 50000; // Default max value, updated dynamically.
  String? _selectedRadio;
  String? _selectedDropdown;
  final List<Map<String, dynamic>> _additionalRows = [];
  final _purposeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$');

  // Variables to store API configurations
  Map<String, dynamic> _config = {};
  List<String> _repaymentDelayOptions = [];
  List<String> _revenueSharedFrequencyOptions = [];
  List<String> _useOfFundsOptions = [];
  double _desiredFeePercentage = 0.5; // Default value
  double _fundingAmountMin = 25000; // Default value
  double _fundingAmountMax = 750000; // Default value

  @override
  void initState() {
    super.initState();
    _fetchConfig(); // Fetch configuration when the page loads
  }

  // Fetch configuration from the API
  Future<void> _fetchConfig() async {
    final response = await http.get(Uri.parse(
        'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json'));
    if (response.statusCode == 200) {
      final List<dynamic> configList = json.decode(response.body);
      setState(() {
        _config = {for (var item in configList) item['name']: item};
        _repaymentDelayOptions =
            _config['desired_repayment_delay']?['value'].split('*') ?? [];
        _revenueSharedFrequencyOptions =
            _config['revenue_shared_frequency']?['value'].split('*') ?? [];
        _useOfFundsOptions = _config['use_of_funds']?['value'].split('*') ?? [];
        _desiredFeePercentage = double.tryParse(
                _config['desired_fee_percentage']?['value'] ?? '0.5') ??
            0.5;
        _fundingAmountMin = double.tryParse(
                _config['funding_amount_min']?['value'] ?? '25000') ??
            25000;
        _fundingAmountMax = double.tryParse(
                _config['funding_amount_max']?['value'] ?? '750000') ??
            750000;
      });
    } else {
      throw Exception('Failed to load configuration');
    }
  }

  void _addRow() {
    if (_purposeController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty) {
      setState(() {
        _additionalRows.add({
          'purpose': _purposeController.text,
          'description': _descriptionController.text,
          'amount': _amountController.text,
        });
        _purposeController.clear();
        _descriptionController.clear();
        _amountController.clear();
      });
    }
  }

  void _removeRow(int index) {
    setState(() {
      _additionalRows.removeAt(index);
    });
  }

  // Calculate repayment rate
  double _calculateRepaymentRate() {
    if (_revenueController.text.isEmpty || _sliderValue == null) return 0.0;
    final revenueAmount = double.tryParse(
            _revenueController.text.replaceAll(",", "").replaceAll("\$", "")) ??
        0.0;
    final loanAmount = _sliderValue ?? 0.0;
    return (0.156 / 6.2055 / revenueAmount) * (loanAmount * 10) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financing Options'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 200.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Revenue Amount Field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(
                  text: TextSpan(
                    text: _config['revenue_amount']?['label'] ??
                        'What is your annual business revenue?',
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    children: const [
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              TextFormField(
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter()
                ],
                controller: _revenueController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(10.0)),
                      borderSide: BorderSide.none // Change border radius
                      ),
                  labelText: '250,000',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10.0), // Adjust spacing as needed
                    child: Text('\$ '), // Your prefix text
                  ),
                  filled: true, // Enable background fill
                  fillColor: Colors.grey[200], // Set greyish background color
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  if (double.tryParse(value.replaceAll(',', '')) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  final revenue = double.tryParse(
                      value.replaceAll(',', '').replaceAll('\$', ''));
                  if (revenue != null) {
                    setState(() {
                      // Set max slider value to 1/3 of the revenue
                      _maxSliderValue = (revenue / 3)
                          .clamp(_fundingAmountMin, _fundingAmountMax);
                      _sliderValue =
                          null; // Reset slider value when revenue changes.
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Desired Loan Amount Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _config['funding_amount']?['label'] ??
                          'What is your desired loan amount?',
                      style: const TextStyle(fontSize: 18)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_currencyFormat.format(_fundingAmountMin),
                          style: TextStyle(fontSize: 18)),
                      Text(_currencyFormat.format(_maxSliderValue),
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _sliderValue ?? _fundingAmountMin,
                            min: _fundingAmountMin,
                            max: _maxSliderValue, // Dynamic max value
                            divisions: 100,
                            label: _sliderValue != null
                                ? _currencyFormat.format(_sliderValue)
                                : 'Select a value',
                            onChanged: (value) {
                              setState(() {
                                _sliderValue = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: TextEditingController(
                              text: _sliderValue != null
                                  ? NumberFormat('#,###').format(_sliderValue)
                                  : '',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              ThousandsSeparatorInputFormatter()
                            ],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10.0)),
                                  borderSide:
                                      BorderSide.none // Change border radius
                                  ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(
                                    10.0), // Adjust spacing as needed
                                child: Text('\$ '), // Your prefix text
                              ),
                              filled: true, // Enable background fill
                              fillColor: Colors
                                  .grey[200], // Set greyish background color
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF1877F2),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                            onChanged: (value) {
                              final newValue = double.tryParse(value
                                  .replaceAll(',', '')
                                  .replaceAll('\$', ''));
                              if (newValue != null) {
                                setState(() {
                                  _sliderValue = newValue.clamp(
                                      _fundingAmountMin, _maxSliderValue);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Revenue Percentage
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 18, color: Colors.black), // Default style
                  children: [
                    const TextSpan(text: 'Revenue Percentage '),
                    TextSpan(
                      text: '${_calculateRepaymentRate().toStringAsFixed(2)}%',
                      style: const TextStyle(
                          color: Color(0xFF1877F2),
                          fontWeight: FontWeight.bold), // Apply custom color
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Revenue Shared Frequency Radio Buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Revenue Shared Frequency',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 16),
                  Row(
                    children: _revenueSharedFrequencyOptions.map((option) {
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Radio<String>(
                              value: option,
                              groupValue: _selectedRadio,
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedRadio = value;
                                });
                              },
                            ),
                          ),
                          Text(
                              option[0].toUpperCase() +
                                  option.substring(1).toLowerCase(),
                              style: TextStyle(fontSize: 18)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Desired Repayment Delay Dropdown
              Row(
                children: [
                  Text('Desired Repayment Delay',
                      style: const TextStyle(fontSize: 18)),
                  SizedBox(width: 20),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true, // Fill the background
                        fillColor:
                            Colors.grey[200], // Change the background color
                        enabledBorder: OutlineInputBorder(
                          // Remove the underline
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.only(
                            // Add border radius to the top
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          // Remove the underline on focus
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                      ),
                      value: _selectedDropdown,
                      items: _repaymentDelayOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(
                                  color: _selectedDropdown == value
                                      ? Color(0xFF1877F2)
                                      : null,
                                  fontSize: 18)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDropdown = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select an item' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Use of Funds Dropdown
              const Text('What will you use the funds for?',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: null,
                      items: _useOfFundsOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(
                                  fontSize: 17,
                                  color: _purposeController.text == value
                                      ? Color(0xFF1877F2)
                                      : null)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _purposeController.text = newValue!;
                      },
                      decoration: InputDecoration(
                          filled: true, // Fill the background
                          fillColor:
                              Colors.grey[200], // Change the background color
                          enabledBorder: OutlineInputBorder(
                            // Remove the underline
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.only(
                              // Add border radius to the top
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Remove the underline on focus
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          labelText: 'Purpose'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10.0)),
                            borderSide: BorderSide.none // Change border radius
                            ),
                        filled: true, // Enable background fill
                        fillColor:
                            Colors.grey[200], // Set greyish background color
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10.0)),
                            borderSide: BorderSide.none // Change border radius
                            ),
                        prefixIcon: Padding(
                          padding:
                              EdgeInsets.all(10.0), // Adjust spacing as needed
                          child: Text('\$ '), // Your prefix text
                        ),
                        filled: true, // Enable background fill
                        fillColor:
                            Colors.grey[200], // Set greyish background color
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter()
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Additional Rows List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _additionalRows.length,
                itemBuilder: (context, index) {
                  final row = _additionalRows[index];
                  return ListTile(
                    title: Text(
                        '${row['purpose']} - ${row['description']} (\$${row['amount']})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeRow(index),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Next Button
              Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        // Inside the onPressed method of the NEXT button
                        if (_formKey.currentState!.validate() &&
                            _sliderValue != null) {
                          // Logic for navigation
                          final double businessRevenue = double.parse(
                              _revenueController.text
                                  .replaceAll(",", "")
                                  .replaceAll("\$", ""));
                          final double fundingAmount = _sliderValue ?? 0;
                          final double fees =
                              fundingAmount * _desiredFeePercentage;
                          final double totalRevenueShare = fundingAmount + fees;
                          final double revenueSharePercentage =
                              6.03; // Directly use the provided percentage

                          final expectedTransfers = revenueSharePercentage != 0
                              ? (_selectedRadio == 'weekly'
                                  ? (totalRevenueShare * 52) /
                                      (businessRevenue *
                                          (revenueSharePercentage / 100))
                                  : (totalRevenueShare * 12) /
                                      (businessRevenue *
                                          (revenueSharePercentage / 100)))
                              : 0;

                          final expectedTransfersDouble =
                              expectedTransfers.ceil().toDouble();

                          final repaymentDelay = int.tryParse(_selectedDropdown
                                      ?.replaceAll(RegExp(r'[^0-9]'), '') ??
                                  '0') ??
                              0;
                          final expectedCompletionDate = DateTime.now().add(
                            Duration(
                              days: (_selectedRadio == 'weekly'
                                          ? expectedTransfersDouble * 7
                                          : expectedTransfersDouble * 30)
                                      .toInt() +
                                  repaymentDelay,
                            ),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultsPage(
                                businessRevenue: businessRevenue,
                                fundingAmount: fundingAmount,
                                fees: fees,
                                totalRevenueShare: totalRevenueShare,
                                expectedTransfers: expectedTransfersDouble,
                                revenueShareFrequency: _selectedRadio ?? '',
                                expectedCompletionDate: expectedCompletionDate,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Color(0xFF1877F2), // Set background color to blue
                        foregroundColor:
                            Colors.white, // Set font color to white
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text(
                        'NEXT',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultsPage extends StatelessWidget {
  final double businessRevenue;
  final double fundingAmount;
  final double fees;
  final double totalRevenueShare;
  final double expectedTransfers;
  final String revenueShareFrequency;
  final DateTime expectedCompletionDate;

  const ResultsPage({
    required this.businessRevenue,
    required this.fundingAmount,
    required this.fees,
    required this.totalRevenueShare,
    required this.expectedTransfers,
    required this.revenueShareFrequency,
    required this.expectedCompletionDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildRow('Annual Business Revenue:', businessRevenue),
            const SizedBox(height: 10),
            _buildRow('Funding Amount:', fundingAmount),
            const SizedBox(height: 10),
            _buildRow(
                'Fees (${(fees / fundingAmount * 100).toStringAsFixed(2)}%):',
                fees),
            const SizedBox(height: 10),
            Divider(
              thickness: 1,
              color: Color(0xFFC4C4C4),
              indent: MediaQuery.of(context).size.width * 0.1,
              endIndent: MediaQuery.of(context).size.width * 0.1,
            ),
            _buildRow('Total Revenue Share:', totalRevenueShare),
            const SizedBox(height: 10),
            _buildRow('Expected Transfers:', expectedTransfers),
            const SizedBox(height: 10),
            _buildRow('Expected Completion Date:',
                DateFormat.yMMMd().format(expectedCompletionDate)),
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Navigate back to the form page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.white, // Set background color to white
                  foregroundColor: Color(0xFF1877F2), // Set font color to blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text(
                  'BACK',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value, {String? unit}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Text(
            unit != null
                ? NumberFormat('#,###').format(value.ceil())
                : value is double
                    ? (label.contains(
                            'Expected Transfers') // Check if it's expectedTransfers
                        ? NumberFormat('#,###')
                            .format(value.ceil()) // No dollar sign
                        : '\$ ${NumberFormat('#,###.##').format(value)}') // Add dollar sign for other values
                    : value.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: value is String ? Color(0xFF1877F2) : null),
          ),
        ],
      ),
    );
  }
}
