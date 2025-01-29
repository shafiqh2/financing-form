import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Form Example',
      theme: ThemeData(primaryColor: Colors.blue),
      home: const MyFormPage(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financing Options'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              RichText(
                text: const TextSpan(
                  text: 'What is your annual business revenue?',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _revenueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: '\$ ', filled: true),
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
                      _maxSliderValue = revenue / 3;
                      _sliderValue =
                          null; // Reset slider value when revenue changes.
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What is your desired loan amount?'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_currencyFormat.format(0)),
                      Text(_currencyFormat.format(_maxSliderValue)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _sliderValue ?? 0,
                          min: 0,
                          max: _maxSliderValue,
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
                        width: 100,
                        child: TextFormField(
                          controller: TextEditingController(
                            text: _sliderValue != null
                                ? _sliderValue!.toStringAsFixed(0)
                                : '',
                          ),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                          ),
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            final newValue = double.tryParse(
                                value.replaceAll(',', '').replaceAll('\$', ''));
                            if (newValue != null) {
                              setState(() {
                                _sliderValue =
                                    newValue.clamp(0, _maxSliderValue);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_sliderValue != null && _revenueController.text.isNotEmpty)
                Text(
                  'Revenue share percentage: ${((0.156 / 6.2055 / double.parse(_revenueController.text.replaceAll(",", "").replaceAll(r"\$", ""))) * (_sliderValue! * 10) * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Revenue Shared Frequency:'),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'monthly',
                            groupValue: _selectedRadio,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedRadio = value;
                              });
                            },
                          ),
                          const Text('Monthly'),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'weekly',
                            groupValue: _selectedRadio,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedRadio = value;
                              });
                            },
                          ),
                          const Text('Weekly'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Desired Repayment Delay:'),
                  const Spacer(),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _selectedDropdown,
                      items: <String>['30 days', '60 days', '90 days']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
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
              const Text('What will you use the funds for?'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: null,
                      items: <String>[
                        'Marketing',
                        'Personnel',
                        'Working Capital',
                        'Inventory',
                        'Machinery/Equipment',
                        'Other',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _purposeController.text = newValue!;
                      },
                      decoration: const InputDecoration(labelText: 'Purpose'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                      ),
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
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _sliderValue != null) {
                    // Get the values to pass to the ResultsPage
                    final double businessRevenue = double.parse(
                        _revenueController.text
                            .replaceAll(",", "")
                            .replaceAll("\$", ""));
                    final double fundingAmount = _sliderValue ?? 0;
                    final double fees = fundingAmount * 0.5;
                    final double totalRevenueShare = fundingAmount + fees;
                    final double revenueSharePercentage =
                        ((0.156 / 6.2055 / businessRevenue) *
                            (fundingAmount * 10) *
                            100);

                    // Calculate expected transfers
                    final expectedTransfers = revenueSharePercentage != 0
                        ? (totalRevenueShare *
                                (_selectedRadio == 'weekly' ? 52 : 12)) /
                            (businessRevenue * revenueSharePercentage)
                        : 0;

                    // Cast expectedTransfers to double
                    final double expectedTransfersDouble =
                        expectedTransfers.toDouble();

                    // Calculate expected completion date
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

                    // Navigate to the Results page
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
                child: const Text('Next'),
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

  ResultsPage({
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
      appBar: AppBar(title: const Text('Results')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
                'Annual Business Revenue: \$${businessRevenue.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Text('Funding Amount: \$${fundingAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Text('Fees (50%): \$${fees.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Text(
                'Total Revenue Share: \$${totalRevenueShare.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Text(
                'Expected Transfers: ${expectedTransfers.toStringAsFixed(2)} ${revenueShareFrequency == 'weekly' ? 'weeks' : 'months'}'),
            const SizedBox(height: 10),
            Text(
                'Expected Completion Date: ${DateFormat.yMMMd().format(expectedCompletionDate)}'),
          ],
        ),
      ),
    );
  }
}
