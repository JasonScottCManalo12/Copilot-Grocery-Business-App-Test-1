import 'package:flutter/material.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../inventory/screens/stock_adjustment_screen.dart';
import '../../inventory/screens/stock_history_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductRepository _repository = ProductRepository();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _repository.getAll(activeOnly: true);
      setState(() {
        _products = products;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    var list = _products;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_showLowStockOnly) {
      list = list.where((p) => p.isLowStock).toList();
    }

    _filteredProducts = list;
  }

  Future<void> _openForm({Product? product}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
    if (result == true) {
      await _loadProducts();
    }
  }

  Future<void> _openStockAdjustment(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StockAdjustmentScreen(product: product),
      ),
    );
    if (result == true) {
      await _loadProducts();
    }
  }

  void _openStockHistory({Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockHistoryScreen(
          productId: product?.id,
          productName: product?.name,
        ),
      ),
    );
  }

  Future<void> _deactivateProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Product'),
        content: Text(
            'Deactivate "${product.name}"? It will be hidden from the catalogue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && product.id != null) {
      await _repository.softDelete(product.id!);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${product.name}" deactivated')),
        );
      }
    }
  }

  void _showProductActions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                _openForm(product: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Stock In / Out / Adjust'),
              onTap: () {
                Navigator.pop(context);
                _openStockAdjustment(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Stock History'),
              onTap: () {
                Navigator.pop(context);
                _openStockHistory(product: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.red),
              title: const Text('Deactivate'),
              onTap: () {
                Navigator.pop(context);
                _deactivateProduct(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'All stock history',
            onPressed: () => _openStockHistory(),
          ),
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.warning : Icons.warning_amber_outlined,
              color: _showLowStockOnly ? Colors.orange : null,
            ),
            tooltip: 'Show low stock only',
            onPressed: () {
              setState(() {
                _showLowStockOnly = !_showLowStockOnly;
                _applyFilters();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, or barcode...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _showLowStockOnly
                                  ? 'No products match your filters'
                                  : 'No products yet.\nTap + to add your first product.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: product.isLowStock
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                              child: Icon(
                                product.isLowStock
                                    ? Icons.warning_amber
                                    : Icons.inventory_2,
                                color: product.isLowStock
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${product.category} • ${product.stockQuantity.toStringAsFixed(product.stockQuantity.truncateToDouble() == product.stockQuantity ? 0 : 2)} ${product.unit}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₱${product.sellingPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (product.isLowStock)
                                  Text(
                                    'Low stock',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _showProductActions(product),
                            onLongPress: () => _openStockAdjustment(product),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
