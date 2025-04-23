import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../app_links.dart';
import '../models/cargo_model.dart';
import '../models/driver.dart';
import '../common/app_theme.dart';
import 'dart:ui' as ui;
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  Cargo? _selectedCargo;
  double _amountPayable = 0.0;

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
  String _formatDate(String? dateString) {
    if (dateString == null) return 'تاریخ نامشخص';
    try {
      final date = DateTime.parse(dateString);
      return Jalali.fromDateTime(date).formatFullDate();
    } catch (e) {
      return dateString;
    }
  }

  // Calculate driver's income for a cargo
  double _getDriverIncome(Cargo cargo) {
    return cargo.driverIncome ?? 0.0;
  }

  // Calculate amount payable for a selected cargo
  void _calculateAmountPayable(Cargo cargo) {
    setState(() {
      _selectedCargo = cargo;
      _amountPayable = _getDriverIncome(cargo);
      
      // Convert to Toman if needed (since the values in the database are in Rials)
      _amountPayable = _amountPayable / 10;
    });
  }

  // Get filtered cargos based on selected driver and date range
  List<Cargo> _getFilteredCargos() {
    return _cargos.where((cargo) {
      if (_selectedDriverId != null && cargo.driverId != _selectedDriverId) {
        return false;
      }
      if (_startDate != null && cargo.loadingDate != null) {
        try {
        final loadingDate = DateTime.parse(cargo.loadingDate!);
        if (loadingDate.isBefore(_startDate!)) return false;
        } catch (e) {
          // Skip date filtering if parsing fails
        }
      }
      if (_endDate != null && cargo.loadingDate != null) {
        try {
        final loadingDate = DateTime.parse(cargo.loadingDate!);
        if (loadingDate.isAfter(_endDate!)) return false;
        } catch (e) {
          // Skip date filtering if parsing fails
        }
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

  // Helper method to convert Gregorian to Jalali for display with Persian month names
  String _formatJalaliDate(DateTime? dateTime) {
    if (dateTime == null) return 'تاریخ نامشخص';
    final jalali = Jalali.fromDateTime(dateTime);
    // Use a shorter format to avoid overflow
    return '${jalali.formatter.d} ${jalali.formatter.mN} ${jalali.formatter.yy}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredCargos = _getFilteredCargos();
    final totalIncome = _calculateTotalIncome();
    final selectedDriver = _selectedDriverId != null 
        ? _drivers.firstWhere((driver) => driver.id == _selectedDriverId, orElse: () => Driver(id: 0, firstName: '', lastName: ''))
        : null;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('گزارش درآمد رانندگان', 
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            )
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('تلاش مجدد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          // Filter Card
                      Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Driver selection
                                  Text(
                                    'فیلترها',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                value: _selectedDriverId,
                                    decoration: InputDecoration(
                                  labelText: 'انتخاب راننده',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('همه رانندگان'),
                                      ),
                                      ..._drivers.map((driver) {
                                  return DropdownMenuItem<int>(
                                    value: driver.id,
                                    child: Text(driver.fullName),
                                  );
                                }).toList(),
                                    ],
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
                                        child: InkWell(
                                          onTap: () async {
                                            Jalali? picked = await showPersianDatePicker(
                                          context: context,
                                              initialDate: _startDate != null ? Jalali.fromDateTime(_startDate!) : Jalali.now(),
                                              firstDate: Jalali(1380, 1),
                                              lastDate: Jalali.now(),
                                              locale: const Locale('fa', 'IR'),
                                              useRootNavigator: true,
                                              builder: (context, child) {
                                                return Theme(
                                                  data: ThemeData(
                                                    fontFamily: 'Vazir',
                                                    primaryColor: AppTheme.primaryColor,
                                                    colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
                                                    buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                                    textTheme: const TextTheme(
                                                      titleMedium: TextStyle(fontFamily: 'Vazir'),
                                                      bodyLarge: TextStyle(fontFamily: 'Vazir'),
                                                      bodyMedium: TextStyle(fontFamily: 'Vazir'),
                                                      labelLarge: TextStyle(fontFamily: 'Vazir'),
                                                    ),
                                                  ),
                                                  child: Directionality(
                                                    textDirection: ui.TextDirection.rtl,
                                                    child: child!,
                                                  ),
                                                );
                                              },
                                            );
                                            
                                            if (picked != null) {
                                          setState(() {
                                                _startDate = picked.toDateTime();
                                          });
                                        }
                                      },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    _startDate != null
                                                        ? 'از: ${_formatJalaliDate(_startDate!)}'
                                          : 'از تاریخ',
                                                    style: TextStyle(
                                                      color: _startDate != null ? Colors.black : Colors.grey.shade600,
                                                      fontSize: 13,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                  Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            Jalali? picked = await showPersianDatePicker(
                                          context: context,
                                              initialDate: _endDate != null ? Jalali.fromDateTime(_endDate!) : Jalali.now(),
                                              firstDate: Jalali(1380, 1),
                                              lastDate: Jalali.now(),
                                              locale: const Locale('fa', 'IR'),
                                              useRootNavigator: true,
                                              builder: (context, child) {
                                                return Theme(
                                                  data: ThemeData(
                                                    fontFamily: 'Vazir',
                                                    primaryColor: AppTheme.primaryColor,
                                                    colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
                                                    buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                                    textTheme: const TextTheme(
                                                      titleMedium: TextStyle(fontFamily: 'Vazir'),
                                                      bodyLarge: TextStyle(fontFamily: 'Vazir'),
                                                      bodyMedium: TextStyle(fontFamily: 'Vazir'),
                                                      labelLarge: TextStyle(fontFamily: 'Vazir'),
                                                    ),
                                                  ),
                                                  child: Directionality(
                                                    textDirection: ui.TextDirection.rtl,
                                                    child: child!,
                                                  ),
                                                );
                                              },
                                            );
                                            if (picked != null) {
                                          setState(() {
                                                _endDate = picked.toDateTime();
                                          });
                                        }
                                      },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    _endDate != null
                                                        ? 'تا: ${_formatJalaliDate(_endDate!)}'
                                          : 'تا تاریخ',
                                                    style: TextStyle(
                                                      color: _endDate != null ? Colors.black : Colors.grey.shade600,
                                                      fontSize: 13,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                          ),
                        ),
                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Reset filters button
                                  if (_selectedDriverId != null || _startDate != null || _endDate != null)
                                    Center(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedDriverId = null;
                                            _startDate = null;
                                            _endDate = null;
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('پاک کردن فیلترها'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primaryColor,
                                          side: BorderSide(color: AppTheme.primaryColor),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Summary card
                          if (_selectedDriverId != null && selectedDriver != null)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.8),
                                      AppTheme.secondaryColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          radius: 24,
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedDriver.fullName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    Text(
                                              'مجموع درآمد: ${_formatNumber(totalIncome)} تومان',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSummaryItem(
                                          'تعداد بارها',
                                          filteredCargos.length.toString(),
                                        ),
                                        _buildSummaryItem(
                                          'میانگین درآمد هر بار',
                                          filteredCargos.isEmpty
                                              ? '0 تومان'
                                              : '${_formatNumber(totalIncome / filteredCargos.length)} تومان',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Cargo list
                          Text(
                            'لیست بارها ${_selectedDriverId != null ? 'برای ${selectedDriver?.fullName}' : ''}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (filteredCargos.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'هیچ باری با فیلترهای انتخاب شده یافت نشد.',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredCargos.length,
                              itemBuilder: (context, index) {
                                final cargo = filteredCargos[index];
                                return _buildCargoCard(cargo);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
        floatingActionButton: _selectedCargo != null ? FloatingActionButton.extended(
          onPressed: () {
            // Show dialog to confirm payment
            _showPaymentConfirmationDialog();
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.payment),
          label: const Text('پرداخت به راننده'),
        ) : null,
      ),
    );
  }
  
  Widget _buildSummaryItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCargoCard(Cargo cargo) {
    final driverName = cargo.driverName ?? 'نامشخص';
    final driverIncome = _getDriverIncome(cargo);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _calculateAmountPayable(cargo);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'از ${cargo.origin} به ${cargo.destination}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cargo.cargoTypeName ?? 'نامشخص',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCargoInfo(Icons.calendar_today, 'تاریخ حمل: ${_formatDate(cargo.loadingDate)}'),
                  const SizedBox(width: 16),
                  _buildCargoInfo(Icons.local_shipping, 'راننده: $driverName'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCargoInfo(Icons.line_weight, 'وزن: ${cargo.weightTonnes} تن'),
                  const SizedBox(width: 16),
                  _buildCargoInfo(Icons.attach_money, 'درآمد راننده: ${_formatNumber(driverIncome)} تومان'),
                ],
              ),
              // Show indicator that this card is selected
              if (_selectedCargo?.id == cargo.id)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'مبلغ قابل پرداخت: ${_formatNumber(_amountPayable)} تومان',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCargoInfo(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Show confirmation dialog for payment
  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تایید پرداخت'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('آیا از پرداخت مبلغ ${_formatNumber(_amountPayable)} تومان به راننده مطمئن هستید؟'),
            if (_selectedCargo != null && _selectedCargo!.driverName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('راننده: ${_selectedCargo!.driverName}'),
              ),
            if (_selectedCargo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('مسیر: ${_selectedCargo!.origin} به ${_selectedCargo!.destination}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Implement actual payment process
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('پرداخت با موفقیت انجام شد'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              setState(() {
                _selectedCargo = null;
              });
            },
            child: const Text('تایید پرداخت'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
} 