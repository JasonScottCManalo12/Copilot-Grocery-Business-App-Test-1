import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';

enum StockAction { stockIn, stockOut, adjust }

class StockAdjustmentScreen extends StatefulWidget {
  final Product product;
  final StockAction initialAction;

  const StockAdjustmentScreen({
    super.key,
    required this.product,
    this.initialAction = StockAction.stockIn,
  });

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductRepository _repository = ProductRepository();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  late StockAction _action;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final qty = double.parse(_quantityController.text);
      final reason = _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim();

      switch (_action) {
        case StockAction.stockIn:
          await _repository.stockIn(
            productId: widget.product.id!,
            quantity: qty,
            reason: reason,
          );
          break;
        case StockAction.stockOut:
          await _repository.stockOut(
            productId: widget.product.id!,
            quantity: qty,
            reason: reason,
          );
          break;
        case StockAction.adjust:
          await _repository.adjustStock(
            productId: widget.product.id!,
            newQuantity: qty,
            reason: reason,
          );
          break;
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String get _actionTitle {
    switch (_action) {
      case StockAction.stockIn:
        return 'Stock In';
      case StockAction.stockOut:
        return 'Stock Out';
      case StockAction.adjust:
        return 'Set Stock Quantity';
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(_actionTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current stock: ${product.stockQuantity.toStringAsFixed(product.stockQuantity.truncateToDouble() == product.stockQuantity ? 0 : 2)} ${product.unit}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    if (product.isLowStock)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber,
                                size: 16, color: Colors.orange[800]),
                            const SizedBox(width: 4),
                            Text(
                              'Low stock (threshold: ${product.lowStockThreshold})',
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action selector
            SegmentedButton<StockAction>(
              segments: const [
                ButtonSegment(
                  value: StockAction.stockIn,
                  label: Text('Stock In'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment(
                  value: StockAction.stockOut,
                  label: Text('Stock Out'),
                  icon: Icon(Icons.remove),
                ),
                ButtonSegment(
                  value: StockAction.adjust,
                  label: Text('Set Qty'),
                  icon: Icon(Icons.edit),
                ),
              ],
              selected: {_action},
              onSelectionChanged: (s) => setState(() => _action = s.first),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: _action == StockAction.adjust
                    ? 'New Stock Quantity *'
                    : 'Quantity *',
                border: const OutlineInputBorder(),
                suffixText: product.unit,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n < 0) return 'Enter a valid number';
                if (_action == StockAction.stockOut && n > product.stockQuantity) {
                  return 'Cannot exceed current stock';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason / Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g. Delivery from supplier, Spoilage, Count correction',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Confirm'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
