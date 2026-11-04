import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sale.dart';

class SaleCompleteScreen extends StatelessWidget {
  final Sale sale;

  const SaleCompleteScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Complete'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Success header
          Column(
            children: [
              Icon(Icons.check_circle, size: 72, color: Colors.green[600]),
              const SizedBox(height: 12),
              const Text(
                'Payment Successful',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                sale.transactionId,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              Text(
                dateFormat.format(sale.createdAt),
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...sale.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} × ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)}',
                              ),
                            ),
                            Text('₱${item.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
                  const Divider(),
                  _row('Subtotal', sale.subtotal),
                  if (sale.discount > 0) _row('Discount', -sale.discount),
                  _row('Total', sale.total, bold: true),
                  _row('Paid (${sale.paymentMethod.toUpperCase()})',
                      sale.amountReceived),
                  _row('Change', sale.changeAmount),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.point_of_sale),
            label: const Text('New Sale'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
