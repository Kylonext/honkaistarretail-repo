// Path: lib/pages/cart_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../session.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDbCart();
  }

  Future<void> loadDbCart() async {
    try {
      // 🟢 FIXED: Menambahkan rute /api/
      final response = await http.get(
        Uri.parse('${Session.baseUrl}/api/cart'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      );
      
      // 🟢 FIXED: Amankan jika widget unmounted saat menunggu respon internet
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          cartItems = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  double get grandTotal {
    return cartItems.fold(0, (sum, item) => sum + (double.parse(item['price'].toString()) * item['quantity']));
  }

  Future<void> removeItem(int cartEntryId) async {
    try {
      // 🟢 FIXED: Menambahkan rute /api/
      final response = await http.delete(
        Uri.parse('${Session.baseUrl}/api/cart/$cartEntryId'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      );
      
      // 🟢 FIXED: Amankan state context sebelum memuat ulang data database
      if (!mounted) return;

      if (response.statusCode == 200) {
        loadDbCart();
      }
    } catch (_) {
      // Menghindari unhandled async exception
    }
  }

  Future<void> checkout() async {
    if (cartItems.isEmpty) return;

    try {
      // 🟢 FIXED: Menambahkan rute /api/
      final response = await http.post(
        Uri.parse('${Session.baseUrl}/api/cart/checkout'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      );

      // 🟢 FIXED: Amankan context sebelum memunculkan AlerDialog UI
      if (!mounted) return;

      if (response.statusCode == 200) {
        for (var item in cartItems) {
          Session.orderHistory.add("Dispatched ${item['quantity']}x ${item['name']}");
        }
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Transaction Cleared!"),
            content: const Text("Order pushed to database inventory changes successfully."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          ),
        ).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      }
    } catch (_) {
      // Menghindari unhandled async exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Database Cart Ledger"), backgroundColor: Colors.transparent, elevation: 0),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : cartItems.isEmpty
              ? const Center(child: Text("Database cart table is empty for your session."))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final subtotal = double.parse(item['price'].toString()) * item['quantity'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Qty: ${item['quantity']} × \$${item['price']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("\$${subtotal.toStringAsFixed(2)}", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => removeItem(item['cart_entry_id']),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Grand Total:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text("\$${grandTotal.toStringAsFixed(2)}", style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                                onPressed: checkout,
                                child: const Text("PURCHASE"),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}