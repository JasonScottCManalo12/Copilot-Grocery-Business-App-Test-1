import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/sale_repository.dart';
import 'sale_complete_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SaleRepository _repository = SaleRepository();
  List<Sale> _sales = [];
  bool _isLoading = true;
  double _todayTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _repository.getRecentSales(limit: 100);
      final todayTotal = await _repository.getTodayTotal();
      setState(() {
        _sales = sales;
        _todayTotal = todayTotal;
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // Today summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              children: [
                Text('Today\'s Sales',
                    style: TextStyle(color: Colors.grey[700])),
                Text(
                  '₱${_todayTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? const Center(child: Text('No sales yet'))
                    : ListView.separated(
                        itemCount: _sales.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(Icons.receipt_long,
                                  color: Colors.green),
                            ),
                            title: Text(
                              sale.transactionId,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${dateFormat.format(sale.createdAt)} • ${sale.paymentMethod.toUpperCase()} • ${sale.items.length} items',
                            ),
                            trailing: Text(
                              '₱${sale.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SaleCompleteScreen(sale: sale),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
