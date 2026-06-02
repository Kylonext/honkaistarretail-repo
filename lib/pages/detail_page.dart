import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../session.dart';
import '../theme.dart';
import 'manage_resource_page.dart';

class DetailPage extends StatefulWidget {
  final int id;
  const DetailPage({required this.id, super.key});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? resource;
  int purchaseQty = 1;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    try {
      // 🟢 FIXED: Menambahkan rute /api/
      final response = await http.get(
        Uri.parse('${Session.baseUrl}/api/resources/${widget.id}'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      );
      
      // 🟢 FIXED: Amankan jika widget unmounted selama network request
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() { resource = jsonDecode(response.body); });
      }
    } catch (_) {
    }
  }

  Future<void> addtoDbCart() async {
    if (purchaseQty > resource!['stock']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient stock available inside vault!")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Session.baseUrl}/api/cart'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${Session.token}'},
        body: jsonEncode({'resource_id': resource!['id'], 'quantity': purchaseQty}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved item to your database schema cart!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to connect to server."), backgroundColor: Colors.redAccent)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (resource == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(resource!['name']),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: Session.role == 'admin' ? [
          IconButton(icon: const Icon(Icons.edit), onPressed: () async {
            final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => ManageResourcePage(resource: resource)));
            if (updated == true) loadDetails();
          }),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Purge Resource?"),
                  content: const Text("Permanently drop this row from database?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("PURGE", style: TextStyle(color: Colors.redAccent))),
                  ],
                )
              );
              
              if (confirm == true) {
                try {
                  // 🟢 FIXED: Menambahkan rute /api/ untuk proses hapus admin
                  final response = await http.delete(
                    Uri.parse('${Session.baseUrl}/api/resources/${widget.id}'),
                    headers: {'Authorization': 'Bearer ${Session.token}'},
                  );
                  
                  if (!mounted) return;

                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                  }
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Delete query failed."), backgroundColor: Colors.redAccent)
                  );
                }
              }
            }
          )
        ] : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: SpaceTheme.renderImage(resource!['image_url'], height: 220, width: 220))),
                  const SizedBox(height: 24),
                  Text(resource!['name'], style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(resource!['type'], style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(resource!['description'], style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  Text("Available Stock Vault: ${resource!['stock']}", style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
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
                        Text("\$${(double.parse(resource!['price'].toString()) * purchaseQty).toStringAsFixed(2)}", style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        if (Session.role == 'user') Row(
                          children: [
                            IconButton(onPressed: () { if(purchaseQty > 1) setState(() => purchaseQty--); }, icon: const Icon(Icons.remove_circle_outline)),
                            Text("$purchaseQty", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(onPressed: () => setState(() => purchaseQty++), icon: const Icon(Icons.add_circle_outline)),
                          ],
                        )
                      ],
                    ),
                    if (Session.role == 'user') ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        onPressed: addtoDbCart,
                        child: const Text("ADD TO CART MANIFEST"),
                      )
                    ]
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