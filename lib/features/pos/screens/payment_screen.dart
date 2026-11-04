import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final int itemCount;

  const PaymentScreen({
    super.key,
    required this.total,
    required this.itemCount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  String _paymentMethod = AppConstants.paymentCash;
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amountReceived =>
      double.tryParse(_amountController.text) ?? 0.0;

  double get _finalTotal => widget.total - _discount;

  double get _change => _amountReceived - _finalTotal;

  void _setExact() {
    _amountController.text = _finalTotal.toStringAsFixed(2);
    setState(() {});
  }

  void _confirm() {
    if (_amountReceived < _finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount received is insufficient')),
      );
      return;
    }

    Navigator.pop(context, {
      'paymentMethod': _paymentMethod,
      'amountReceived': _amountReceived,
      'discount': _discount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${widget.itemCount} items',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    '₱${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_discount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Discount: -₱${_discount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    Text(
                      'Total due: ₱${_finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment method
          const Text('Payment Method',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppConstants.paymentMethods.map((method) {
              final selected = _paymentMethod == method;
              return ChoiceChip(
                label: Text(method.toUpperCase()),
                selected: selected,
                onSelected: (_) => setState(() => _paymentMethod = method),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Amount received
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount Received',
              prefixText: '₱ ',
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(
                onPressed: _setExact,
                child: const Text('Exact'),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Quick amounts
          if (_paymentMethod == AppConstants.paymentCash)
            Wrap(
              spacing: 8,
              children: [50, 100, 200, 500, 1000].map((amount) {
                return ActionChip(
                  label: Text('₱$amount'),
                  onPressed: () {
                    _amountController.text = amount.toStringAsFixed(2);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Change
          if (_amountReceived >= _finalTotal)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change',
                      style: TextStyle(fontSize: 18)),
                  Text(
                    '₱${_change.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: _amountReceived >= _finalTotal ? _confirm : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Complete Sale', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
