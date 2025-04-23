import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../models/cargo_model.dart';
import '../app_links.dart';
import 'package:flutter/rendering.dart' as ui;

class CargoDetailsScreen extends StatelessWidget {
  static const routeName = '/cargo-details';

  final Cargo cargo;

  const CargoDetailsScreen({
    super.key,
    required this.cargo,
  });

  @override
  Widget build(BuildContext context) {
    // تبدیل و فرمت تاریخ با تقویم جلالی
    final loadingDateFormatted = cargo.loadingDate != null 
        ? Jalali.fromDateTime(DateTime.parse(cargo.loadingDate!)).formatFullDate()
        : 'نامشخص';
    
    final unloadingDateFormatted = cargo.unloadingDate != null 
        ? Jalali.fromDateTime(DateTime.parse(cargo.unloadingDate!)).formatFullDate()
        : 'نامشخص';

    // فرمت‌دهی اعداد با جداکننده هزارگان
    final NumberFormat numberFormat = NumberFormat('#,###', 'fa');
    final weightFormatted = numberFormat.format(cargo.weightTonnes);
    
    // تبدیل مبالغ از ریال به تومان (تقسیم بر ۱۰)
    final pricePerTonToman = cargo.pricePerTonne / 10;
    final transportCostPerTonToman = cargo.transportCostPerTonne / 10;
    final waybillAmountToman = cargo.waybillAmount != null ? cargo.waybillAmount! / 10 : null;
    
    final priceFormatted = numberFormat.format(pricePerTonToman);
    final transportCostFormatted = numberFormat.format(transportCostPerTonToman);
    final waybillAmountFormatted = waybillAmountToman != null 
        ? numberFormat.format(waybillAmountToman)
        : 'نامشخص';
    
    // محاسبه مبلغ کل (تومان)
    final totalAmount = cargo.weightTonnes * pricePerTonToman;
    final totalAmountFormatted = numberFormat.format(totalAmount);
    
    // محاسبه هزینه کل حمل (تومان)
    final totalTransportCost = cargo.weightTonnes * transportCostPerTonToman;
    final totalTransportCostFormatted = numberFormat.format(totalTransportCost);

    print("Original weight from server: ${cargo.weightTonnes}");
    print("Original price from server: ${cargo.pricePerTonne}");
    print("Original transport cost from server: ${cargo.transportCostPerTonne}");

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جزئیات بار'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // کارت اصلی مسیر
              _buildRouteCard(context),
              
              const SizedBox(height: 16),
              
              // اطلاعات خودرو و راننده
              _buildSectionTitle(context, 'اطلاعات حمل و نقل'),
              _buildDataCard(context, [
                _buildDataRow(
                  context,
                  'خودرو:',
                  cargo.vehicleName ?? 'نامشخص',
                ),
                _buildDataRow(
                  context,
                  'راننده:',
                  cargo.driverName ?? 'نامشخص',
                ),
                _buildDataRow(
                  context,
                  'شرکت حمل و نقل:',
                  cargo.shippingCompanyName ?? 'نامشخص',
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // اطلاعات بار
              _buildSectionTitle(context, 'اطلاعات بار'),
              _buildDataCard(context, [
                _buildDataRow(
                  context,
                  'نوع بار:',
                  cargo.cargoTypeName ?? 'نامشخص',
                ),
                _buildDataRow(
                  context,
                  'شرکت فروشنده:',
                  cargo.sellingCompanyName ?? 'نامشخص',
                ),
                _buildDataRow(
                  context,
                  'وزن (تن):',
                  weightFormatted,
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // اطلاعات تاریخ
              _buildSectionTitle(context, 'تاریخ حمل'),
              _buildDataCard(context, [
                _buildDataRow(
                  context,
                  'مبدأ:',
                  cargo.origin,
                ),
                _buildDataRow(
                  context,
                  'مقصد:',
                  cargo.destination,
                ),
                if (cargo.loadingDate != null)
                  _buildDataRow(
                    context,
                    'تاریخ بارگیری:',
                    _formatDate(cargo.loadingDate!),
                  ),
                if (cargo.unloadingDate != null)
                  _buildDataRow(
                    context,
                    'تاریخ تخلیه:',
                    _formatDate(cargo.unloadingDate!),
                  ),
              ]),
              
              const SizedBox(height: 16),
              
              // اطلاعات مالی
              _buildSectionTitle(context, 'اطلاعات مالی'),
              _buildDataCard(context, [
                _buildDataRow(
                  context,
                  'مشتری:',
                  cargo.customerName ?? 'نامشخص',
                ),
                _buildDataRow(
                  context,
                  'قیمت هر تن (تومان):',
                  priceFormatted,
                ),
                _buildDataRow(
                  context,
                  'مبلغ کل (تومان):',
                  totalAmountFormatted,
                  valueColor: Colors.green,
                ),
                _buildDataRow(
                  context,
                  'هزینه حمل هر تن (تومان):',
                  transportCostFormatted,
                ),
                _buildDataRow(
                  context,
                  'هزینه کل حمل (تومان):',
                  totalTransportCostFormatted,
                  valueColor: Colors.green,
                ),
                _buildDataRow(
                  context,
                  'مبلغ بارنامه (تومان):',
                  waybillAmountFormatted,
                ),
                _buildDataRow(
                  context,
                  'وضعیت پرداخت مشتری:',
                  cargo.customerPaymentStatusName ?? 'نامشخص',
                  valueColor: getPaymentStatusColor(cargo.customerPaymentStatusName),
                ),
                _buildDataRow(
                  context,
                  'پرداخت به فروشنده:',
                  cargo.sellerPaymentStatus ? 'انجام شده' : 'انجام نشده',
                ),
                _buildDataRow(
                  context,
                  'وضعیت پرداخت به راننده:',
                  _getDriverPaymentStatus(cargo.id),
                  valueColor: _getDriverPaymentColor(cargo.id),
                ),
                if (cargo.customerBankAccountName != null)
                  _buildDataRow(
                    context,
                    'حساب بانکی مشتری:',
                    cargo.customerBankAccountName!,
                  ),
                _buildDataRow(
                  context,
                  'مجموع پرداختی:',
                  _formatNumber(cargo.weightTonnes * cargo.pricePerTonne) + ' AFN',
                  valueColor: Colors.green,
                ),
              ]),
              
              // نمایش تصویر بارنامه اگر موجود باشد
              if (cargo.waybillImage != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'تصویر بارنامه'),
                _buildWaybillImage(context),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'مسیر حمل',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مبدأ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cargo.origin,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Icon(
                        Icons.arrow_forward, 
                        color: Colors.white.withOpacity(0.8),
                        size: 28,
                      ),
                      Text(
                        '${_formatNumber(cargo.weightTonnes)} تن',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مقصد',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cargo.destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Show loading and unloading dates if available
            if (cargo.loadingDate != null || cargo.unloadingDate != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (cargo.loadingDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تاریخ بارگیری',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                Jalali.fromDateTime(DateTime.parse(cargo.loadingDate!)).formatCompactDate(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (cargo.unloadingDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'تاریخ تخلیه',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                Jalali.fromDateTime(DateTime.parse(cargo.unloadingDate!)).formatCompactDate(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.arrow_left,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title on the right side
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          
          // Spacer
          const SizedBox(width: 16),
          
          // Value on the left side
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: valueColor ?? Colors.black,
                fontSize: 14.0,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaybillImage(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: cargo.waybillImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${AppLinks.baseUrl}/uploads/${cargo.waybillImage}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format numbers
  String _formatNumber(double value) {
    return NumberFormat('#,###', 'fa').format(value);
  }

  String _formatDate(String date) {
    // Implement your logic to format the date
    // For example, you can use the Jalali class to format the date
    return Jalali.fromDateTime(DateTime.parse(date)).formatFullDate();
  }

  Color getPaymentStatusColor(String? paymentStatus) {
    // Implement your logic to determine the color based on the payment status
    // For example, you can use a switch statement or a map to return the appropriate color
    switch (paymentStatus) {
      case 'Paid':
        return Colors.green;
      case 'Unpaid':
        return Colors.red;
      case 'Partially Paid':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  // Method to get driver payment status text based on cargo ID
  String _getDriverPaymentStatus(int? cargoId) {
    if (cargoId == null) return 'پرداخت نشده';
    
    // Check if we have payment status data
    try {
      final Map<String, dynamic> statusData = _fetchDriverSalaryStatus(cargoId);
      return statusData['paid'] ? 'پرداخت شده' : 'پرداخت نشده';
    } catch (e) {
      return 'پرداخت نشده';
    }
  }
  
  // Get color for driver payment status
  Color _getDriverPaymentColor(int? cargoId) {
    if (cargoId == null) return Colors.red;
    
    try {
      final Map<String, dynamic> statusData = _fetchDriverSalaryStatus(cargoId);
      return statusData['paid'] ? Colors.green : Colors.red;
    } catch (e) {
      return Colors.red;
    }
  }
  
  // Fetch driver salary payment status
  Map<String, dynamic> _fetchDriverSalaryStatus(int cargoId) {
    // This implementation would actually fetch data from the API
    // In a production app, this would be replaced with a call to the API
    // and should be made async
    try {
      // Mock implementation
      // In a real-world scenario, we would use this:
      /*
      final response = await http.get(Uri.parse('${AppLinks.driverSalary}?cargo_id=$cargoId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'paid': true,
            'amount': data[0]['amount'] != null ? double.parse(data[0]['amount'].toString()) : 0.0,
            'payment_date': data[0]['payment_date'],
          };
        }
      }
      */
      
      // For now, return mock data
      // In a real implementation, we'd also cache this data
      return {'paid': false, 'amount': 0.0};
    } catch (e) {
      print('Error fetching driver salary status: $e');
      return {'paid': false, 'amount': 0.0};
    }
  }
} 