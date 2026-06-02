import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    Widget buildMemberCard(String name, String nim) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withAlpha(40),
                child: Icon(Icons.person, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "NIM: $nim",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Specifications"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Metadata Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups, color: primaryColor, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        "Development Team",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    "Group ID:",
                    style: TextStyle(fontWeight: FontWeight.w600, color: subTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    "034ec8b9-7531-f111-a1d4-9440c921bcaf",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              "CREW MANIFEST",
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Roster List
            buildMemberCard("Bryan Felix Ong", "2802495745"),
            buildMemberCard("Sabrina Salma Almira", "2802511105"),
            buildMemberCard("Farrel Ganendra Putra Fadia", "2802499150"),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                "Honkai Star Retail Application Portfolio • Mobile Hybrid Solution",
                style: TextStyle(color: subTextColor, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}