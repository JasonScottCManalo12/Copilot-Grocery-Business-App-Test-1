import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/stock_movement.dart';
import '../../../data/repositories/product_repository.dart';

class StockHistoryScreen extends StatefulWidget {
  final int? productId; // null = all products
  final String? productName;

  const StockHistoryScreen({
    super.key,
    this.productId,
    this.productName,
  });

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final ProductRepository _repository = ProductRepository();
  List<StockMovement> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getMovements(
        productId: widget.productId,
        limit: 200,
      );
      setState(() {
        _movements = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'stock_in':
      case 'return':
        return Colors.green;
      case 'stock_out':
      case 'sale':
        return Colors.red;
      case 'adjustment':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'stock_in':
        return Icons.add_circle_outline;
      case 'stock_out':
        return Icons.remove_circle_outline;
      case 'adjustment':
        return Icons.tune;
      case 'sale':
        return Icons.shopping_cart_outlined;
      case 'return':
        return Icons.keyboard_return;
      default:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName != null
            ? 'History • ${widget.productName}'
            : 'Stock History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No stock movements yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _movements.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = _movements[index];
                    final color = _typeColor(m.type);
                    final isIncrease = m.isIncrease;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(_typeIcon(m.type), color: color, size: 20),
                      ),
                      title: Text(
                        widget.productId == null ? m.productName : m.typeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.productId == null)
                            Text(m.typeLabel,
                                style: TextStyle(color: color, fontSize: 13)),
                          Text(
                            dateFormat.format(m.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (m.reason != null && m.reason!.isNotEmpty)
                            Text(
                              m.reason!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncrease ? '+' : '-'}${m.quantity.toStringAsFixed(m.quantity.truncateToDouble() == m.quantity ? 0 : 2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${m.previousStock.toStringAsFixed(0)} → ${m.newStock.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
