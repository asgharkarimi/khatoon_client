import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../app_links.dart';
import '../models/cargo_model.dart';
import '../models/driver.dart';
import '../widgets/app_buttons.dart';
import 'dart:ui' as ui;

class DriverIncomeReportScreen extends StatefulWidget {
  static const routeName = '/driver-income-report';

  const DriverIncomeReportScreen({super.key});

  @override
  State<DriverIncomeReportScreen> createState() => _DriverIncomeReportScreenState();
}

class _DriverIncomeReportScreenState extends State<DriverIncomeReportScreen> {
  List<Cargo> _cargos = [];
  List<Driver> _drivers = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedDriverId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch cargos and drivers in parallel
      final cargosResponse = await http.get(Uri.parse(AppLinks.cargos));
      final driversResponse = await http.get(Uri.parse(AppLinks.drivers));

      if (cargosResponse.statusCode == 200 && driversResponse.statusCode == 200) {
        final List<dynamic> cargoData = json.decode(cargosResponse.body);
        final List<dynamic> driverData = json.decode(driversResponse.body);

        setState(() {
          _cargos = cargoData.map((data) => Cargo.fromJson(data)).toList();
          _drivers = driverData.map((data) => Driver.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت اطلاعات';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Format numbers with Persian thousands separator
  String _formatNumber(double value) {
    return NumberFormat('#,###', 'fa').format(value);
  }

  // Format date string to a human-readable format
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }

  // Calculate driver's income for a cargo - Use the server-provided value
  double _getDriverIncome(Cargo cargo) {
    // Return the server-calculated income value
    return cargo.driverIncome ?? 0.0;
  }

  // Get filtered cargos based on selected driver and date range
  List<Cargo> _getFilteredCargos() {
    return _cargos.where((cargo) {
      if (_selectedDriverId != null && cargo.driverId != _selectedDriverId) {
        return false;
      }
      if (_startDate != null && cargo.loadingDate != null) {
        final loadingDate = DateTime.parse(cargo.loadingDate!);
        if (loadingDate.isBefore(_startDate!)) return false;
      }
      if (_endDate != null && cargo.loadingDate != null) {
        final loadingDate = DateTime.parse(cargo.loadingDate!);
        if (loadingDate.isAfter(_endDate!)) return false;
      }
      return true;
    }).toList();
  }

  // Calculate total income for selected driver
  double _calculateTotalIncome() {
    if (_selectedDriverId == null) return 0;
    
    final filteredCargos = _getFilteredCargos();
    
    return filteredCargos.fold(0, (sum, cargo) => sum + _getDriverIncome(cargo));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('گزارش درآمد رانندگان'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      // Filters
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Driver selection
                              DropdownButtonFormField<int>(
                                value: _selectedDriverId,
                                decoration: const InputDecoration(
                                  labelText: 'انتخاب راننده',
                                  border: OutlineInputBorder(),
                                ),
                                items: _drivers.map((driver) {
                                  return DropdownMenuItem<int>(
                                    value: driver.id,
                                    child: Text(driver.fullName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDriverId = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              // Date range selection
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButtons.textButton(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _startDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _startDate = date;
                                          });
                                        }
                                      },
                                      label: _startDate != null
                                          ? 'از: ${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                                          : 'از تاریخ',
                                    ),
                                  ),
                                  Expanded(
                                    child: AppButtons.textButton(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _endDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _endDate = date;
                                          });
                                        }
                                      },
                                      label: _endDate != null
                                          ? 'تا: ${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                                          : 'تا تاریخ',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Summary card
                      if (_selectedDriverId != null)
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'جمع درآمد: ${_formatNumber(_calculateTotalIncome())} تومان',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'فرمول محاسبه درآمد راننده: ((وزن بار × هزینه حمل) - مبلغ بارنامه) × درصد حقوق راننده',
                                      child: const Icon(Icons.info_outline, size: 18),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'فرمول محاسبه: ((وزن بار × هزینه حمل) - مبلغ بارنامه) × درصد حقوق',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Cargo list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _getFilteredCargos().length,
                          itemBuilder: (context, index) {
                            final cargo = _getFilteredCargos()[index];
                            final driver = _drivers.firstWhere((d) => d.id == cargo.driverId);
                            final income = _getDriverIncome(cargo);
                            
                            // Calculate total transport cost
                            final totalTransportCost = cargo.weightTonnes * cargo.transportCostPerTonne;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cargo basic info
                                    Text(
                                      '${cargo.origin} به ${cargo.destination}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Transport details
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text('وزن: ${_formatNumber(cargo.weightTonnes)} تن'),
                                        ),
                                        Expanded(
                                          child: Text('هزینه حمل: ${_formatNumber(cargo.transportCostPerTonne)} تومان'),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    
                                    // Income calculation
                                    Text('هزینه کل حمل: ${_formatNumber(totalTransportCost)} تومان'),
                                    if (cargo.waybillAmount != null && cargo.waybillAmount! > 0)
                                      Text('کسر بارنامه: ${_formatNumber(cargo.waybillAmount!)} تومان', 
                                           style: const TextStyle(color: Colors.red)),
                                    Text('درصد حقوق: ${driver.salaryPercentage}%'),
                                    const SizedBox(height: 8),
                                    
                                    // Final income
                                    Text(
                                      'درآمد راننده: ${_formatNumber(income)} تومان',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                    
                                    // Add calculation example
                                    if (cargo.waybillAmount != null && cargo.waybillAmount! > 0)
                                      Text(
                                        'محاسبه: ((${_formatNumber(cargo.weightTonnes)} × ${_formatNumber(cargo.transportCostPerTonne)}) - ${_formatNumber(cargo.waybillAmount!)}) × ${driver.salaryPercentage}%',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      )
                                    else
                                      Text(
                                        'محاسبه: (${_formatNumber(cargo.weightTonnes)} × ${_formatNumber(cargo.transportCostPerTonne)}) × ${driver.salaryPercentage}%',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    
                                    // Loading date if available
                                    if (cargo.loadingDate != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'تاریخ بارگیری: ${_formatDate(cargo.loadingDate!)}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
} 