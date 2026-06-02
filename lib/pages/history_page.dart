import 'package:flutter/material.dart';
import '../session.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logistics History"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Session.orderHistory.isEmpty
          ? const Center(child: Text("No logistics orders dispatched in this session."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: Session.orderHistory.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.verified, color: Theme.of(context).primaryColor),
                    title: Text(
                      Session.orderHistory[index],
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                    ),
                  ),
                );
              },
            ),
    );
  }
}