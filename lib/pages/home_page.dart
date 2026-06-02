// Path: lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../session.dart';
import '../theme.dart';
import '../main.dart';
import 'detail_page.dart';
import 'manage_resource_page.dart';
import 'about_page.dart';
import 'history_page.dart';
import 'login_page.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List resources = [];
  List filteredResources = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchResources();
  }

  Future<void> fetchResources() async {
    try {
      // 🟢 FIXED: Menambahkan rute /api/ agar sesuai dengan endpoint Vercel Express kamu
      final response = await http.get(Uri.parse('${Session.baseUrl}/api/resources'));
      
      // 🟢 FIXED: Amankan state agar tidak terjadi eror unmounted context saat render data
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          resources = jsonDecode(response.body);
          filteredResources = resources;
          isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Honkai Star Retail", style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Theme.of(context).primaryColor),
            onPressed: () => setState(() => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          if (Session.role == 'user') 
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined, color: Theme.of(context).primaryColor),
              onPressed: () async {
                final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                if (updated == true) fetchResources();
              },
            ),
          IconButton(icon: Icon(Icons.history, color: Theme.of(context).primaryColor), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
          IconButton(icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()))),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent), 
            onPressed: () { 
              Session.clearSession(); 
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())); 
            }
          ),
        ],
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search galactic manifest items...",
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                    ),
                    onChanged: (text) {
                      setState(() {
                        filteredResources = resources
                            .where((item) => item['name'].toLowerCase().contains(text.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredResources.isEmpty
                      ? const Center(child: Text("No manifest data matches query."))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: filteredResources.length,
                          itemBuilder: (context, index) {
                            final item = filteredResources[index];
                            return GestureDetector(
                              onTap: () async {
                                final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(id: item['id'])));
                                if (updated == true) fetchResources();
                              },
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: SizedBox(width: double.infinity, child: SpaceTheme.renderImage(item['image_url']))),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(item['type'], style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("\$${item['price']}", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text("Qty: ${item['stock']}", style: const TextStyle(fontSize: 10)),
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: isDark ? Colors.black26 : Colors.grey.shade200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Session User: ${Session.username} (${Session.role.toUpperCase()})",
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54, fontFamily: 'Courier'),
                      ),
                      Row(
                        children: [
                          Icon(Icons.vpn_key_outlined, size: 12, color: Theme.of(context).primaryColor.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            "Bearer Token: ${Session.token.isEmpty ? 'NONE' : Session.token}",
                            style: TextStyle(
                              fontSize: 11, 
                              color: Theme.of(context).primaryColor.withOpacity(0.8), 
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier'
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: Session.role == 'admin' 
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              label: Text("ADD ITEM", style: TextStyle(color: isDark ? SpaceTheme.darkBg : Colors.white, fontWeight: FontWeight.bold)),
              icon: Icon(Icons.add, color: isDark ? SpaceTheme.darkBg : Colors.white),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageResourcePage()));
                fetchResources();
              },
            )
          : null,
    );
  }
}