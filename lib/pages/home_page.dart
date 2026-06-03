import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchResources();
  }

  Future<void> fetchResources() async {
    try {
      final response = await http.get(Uri.parse('${Session.baseUrl}/api/resources'));
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

  void _handleLogout() async {
    Session.clearSession();
    try {
      if (kIsWeb) {
        await GoogleSignIn.instance.disconnect();
      } else {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "HONKAI STAR RETAIL", 
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18)
            ),
            Text(
              "Galactic Manifest Dashboard", 
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 0.5)
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: primaryColor),
            onPressed: () => setState(() => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          if (Session.role == 'user') 
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined, color: primaryColor),
              onPressed: () async {
                final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                if (updated == true) fetchResources();
              },
            ),
          IconButton(
            icon: Icon(Icons.history_toggle_off_rounded, color: primaryColor), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))
          ),
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: primaryColor), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()))
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent), 
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: Column(
                children: [
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search galactic manifest items...",
                          prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                  ),
                  Expanded(
                    child: filteredResources.isEmpty
                        ? const Center(
                            child: Text(
                              "No manifest data matches query.", 
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)
                            )
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 2; 
                              if (constraints.maxWidth > 1200) {
                                crossAxisCount = 6; 
                              } else if (constraints.maxWidth > 800) {
                                crossAxisCount = 4; 
                              } else if (constraints.maxWidth > 550) {
                                crossAxisCount = 3; 
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.72, 
                                ),
                                itemCount: filteredResources.length,
                                itemBuilder: (context, index) {
                                  final item = filteredResources[index];
                                  return GestureDetector(
                                    onTap: () async {
                                      final updated = await Navigator.push(
                                        context, 
                                        MaterialPageRoute(builder: (_) => DetailPage(id: item['id']))
                                      );
                                      if (updated == true) fetchResources();
                                    },
                                    child: Card(
                                      // Jika sedang dark mode, card diset transparan agar menyatu dengan background utama
                                      color: isDark ? Colors.transparent : Theme.of(context).cardColor,
                                      // Hilangkan shadow tebal di mode gelap agar efek transparan terasa bersih
                                      elevation: isDark ? 0 : 3,
                                      shadowColor: primaryColor.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        // Berikan border tipis di mode gelap supaya struktur kartu tetap kelihatan rapi
                                        side: BorderSide(
                                          color: isDark ? Colors.white10 : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              color: Colors.transparent, // Mengikuti background dasar Card
                                              child: SpaceTheme.renderImage(item['image_url']),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'], 
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3), 
                                                  maxLines: 1, 
                                                  overflow: TextOverflow.ellipsis
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item['type'].toString().toUpperCase(), 
                                                  style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w600, letterSpacing: 0.5), 
                                                  maxLines: 1, 
                                                  overflow: TextOverflow.ellipsis
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      "\$${item['price']}", 
                                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(6)
                                                      ),
                                                      child: Text(
                                                        "Qty: ${item['stock']}", 
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)
                                                      ),
                                                    ),
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
                              );
                            },
                          ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey.shade100,
                      border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300, width: 0.5))
                    ),
                    child: screenWidth > 600
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFooterUserText(isDark),
                              _buildFooterTokenText(context),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFooterUserText(isDark),
                              const SizedBox(height: 2),
                              _buildFooterTokenText(context),
                            ],
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Session.role == 'admin' 
          ? FloatingActionButton.extended(
              backgroundColor: primaryColor,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              label: Text("ADD ITEM", style: TextStyle(color: isDark ? SpaceTheme.darkBg : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              icon: Icon(Icons.add_rounded, color: isDark ? SpaceTheme.darkBg : Colors.white),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageResourcePage()));
                fetchResources();
              },
            )
          : null,
    );
  }

  Widget _buildFooterUserText(bool isDark) {
    return Text(
      "Session User: ${Session.username} (${Session.role.toUpperCase()})",
      style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black54, fontFamily: 'Courier'),
    );
  }

  Widget _buildFooterTokenText(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.vpn_key_outlined, size: 11, color: Theme.of(context).primaryColor.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(
          "Bearer Token: ${Session.token.isEmpty ? 'NONE' : (Session.token.length > 15 ? '${Session.token.substring(0, 15)}...' : Session.token)}",
          style: TextStyle(
            fontSize: 10, 
            color: Theme.of(context).primaryColor.withOpacity(0.7), 
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier'
          ),
        ),
      ],
    );
  }
}