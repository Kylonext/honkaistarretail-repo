import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../session.dart';

class ManageResourcePage extends StatefulWidget {
  final Map<String, dynamic>? resource;
  const ManageResourcePage({this.resource, super.key});

  @override
  State<ManageResourcePage> createState() => _ManageResourcePageState();
}

class _ManageResourcePageState extends State<ManageResourcePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();
  final _priceController = TextEditingController();

  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.resource != null) {
      isEdit = true;
      _nameController.text = widget.resource!['name'] ?? '';
      _typeController.text = widget.resource!['type'] ?? '';
      _descController.text = widget.resource!['description'] ?? '';
      _stockController.text = widget.resource!['stock']?.toString() ?? '';
      _imageController.text = widget.resource!['image_url'] ?? '';
      _priceController.text = widget.resource!['price']?.toString() ?? '';
    }
  }

  Future<void> saveResource() async {
    if (!_formKey.currentState!.validate()) return; 

    final bodyData = jsonEncode({
      'name': _nameController.text.trim(),
      'type': _typeController.text.trim(),
      'description': _descController.text.trim(),
      'stock': int.parse(_stockController.text.trim()),
      'image_url': _imageController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
    });

    final url = isEdit 
        ? '${Session.baseUrl}/api/resources/${widget.resource!['id']}' 
        : '${Session.baseUrl}/api/resources';

    try {
      final response = isEdit
          ? await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${Session.token}'}, body: bodyData)
          : await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${Session.token}'}, body: bodyData);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Manifest updated successfully!" : "New item added!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server rejected database insertion query"), backgroundColor: Colors.redAccent)
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network failure. Server unreachable."), backgroundColor: Colors.redAccent)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Modify Manifest Entry" : "Register New Asset"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Item Name", hintText: "e.g., Star Rail Ticket"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Error: Item name cannot be empty.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: "Category / Type", hintText: "e.g., Currency"),
                validator: (val) => (val == null || val.trim().isEmpty) ? "Error: Please specify an item category." : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Manifest Description"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Error: Description is required.";
                  if (val.trim().length < 10) return "Error: Description must be at least 10 characters long.";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Unit Price (\$)", hintText: "0.00"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Error: Price field cannot be blank.";
                  final price = double.tryParse(val);
                  if (price == null) return "Error: Value must be a valid decimal number.";
                  if (price <= 0) return "Error: Asset value must be greater than \$0.00.";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Vault Stock Quantity", hintText: "0"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Error: Stock level cannot be blank.";
                  final stock = int.tryParse(val);
                  if (stock == null) return "Error: Quantity must be a whole number.";
                  if (stock < 0) return "Error: Stock cannot fall below a baseline of 0.";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: "Asset Image URL", hintText: "http://..."),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Error: Image URL path is required.";
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                onPressed: saveResource,
                child: Text(isEdit ? "COMMIT MODIFICATIONS" : "ADD ITEM"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}