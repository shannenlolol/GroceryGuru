import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/compare_item.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({Key? key}) : super(key: key);

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final DatabaseService _dbService = DatabaseService();

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedItemName;

  Future<void> _addCompareItem() async {
    final brand = _brandController.text.trim();
    final price = double.tryParse(_priceController.text);
    final quantity = double.tryParse(_quantityController.text);

    //  Ensure a comparison group is selected
    if (_selectedItemName == null || _selectedItemName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an item name first.")),
      );
      return;
    }

    if (brand.isNotEmpty && price != null && quantity != null && quantity > 0) {
      final newItem = CompareItem(
        id: '',
        name: _selectedItemName!,
        brand: brand,
        totalPrice: price,
        quantity: quantity,
      );

      print(" Saving CompareItem: ${newItem.toMap()}"); // Debugging

      await _dbService.saveCompareItem(newItem);

      //  Ensure UI updates
      setState(() {
        _brandController.clear();
        _priceController.clear();
        _quantityController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black // Dark mode text color
              : Colors.white, // Change hamburger icon color
        ),
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          'Comparer',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black // Dark mode text color
                : Colors.white, // Light mode text color
            fontFamily: 'RobotoSerif',
            fontWeight: FontWeight.bold,
            fontSize: 30, // Adjust text size
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //  Step 1: Enter Item Name (Comparison Group)
            TextField(
              onChanged: (value) {
                setState(() {
                  _selectedItemName = value.trim();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Enter Item Name for Comparison',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            //  Step 2: Enter Brand, Price, Quantity (Only if Item Name is Set)
            if (_selectedItemName != null && _selectedItemName!.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addCompareItem,
                child: const Text('Add to Comparison'),
              ),
            ],

            const SizedBox(height: 16),

            //  Step 3: Display Comparison Groups & Items
            Expanded(
              child: StreamBuilder<Map<String, List<CompareItem>>>(
                stream: _dbService.streamCompareItems(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No items to compare yet.'));
                  }

                  final groupedItems = snapshot.data!;

                  return ListView(
                    children: groupedItems.entries.map((entry) {
                      final itemName = entry.key;
                      final comparisons = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                itemName, //  Display name normally
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteComparisonGroup(
                                    itemName), //  Deletes entire group
                              ),
                            ],
                          ),
                          ...comparisons.map((item) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text('${item.brand} - ${item.name}'),
                                subtitle: Text(
                                  'Price: \$${item.totalPrice.toStringAsFixed(2)} | '
                                  'Qty: ${item.quantity} | '
                                  'Unit: \$${item.unitPrice.toStringAsFixed(2)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _showEditDialog(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteCompareItem(
                                          item.name, item.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(CompareItem item) {
    final nameController = TextEditingController(text: item.name);
    final brandController = TextEditingController(text: item.brand);
    final priceController =
        TextEditingController(text: item.totalPrice.toString());
    final quantityController =
        TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Item Name (Comparison Group)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final brand = brandController.text.trim();
                final totalPrice = double.tryParse(priceController.text) ?? 0;
                final quantity = double.tryParse(quantityController.text) ?? 1;

                if (newName.isNotEmpty && brand.isNotEmpty) {
                  await _dbService.updateCompareItem(
                      item.name, item.id, newName, brand, totalPrice, quantity);

                  //  Delay then refresh UI
                  await Future.delayed(const Duration(milliseconds: 200));
                  setState(() {});

                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCompareItem(String itemName, String itemId) async {
    await _dbService.deleteCompareItem(itemName, itemId);

    print("Deleted CompareItem: $itemId under $itemName");

    //  Delay briefly to let Firestore update before UI refresh
    await Future.delayed(const Duration(milliseconds: 200));

    //  Force UI update by calling setState()
    setState(() {});
  }

  void _deleteComparisonGroup(String itemName) async {
    await _dbService.deleteComparisonGroup(itemName);

    print("Deleted Entire Comparison Group: $itemName");

    //  Delay briefly to let Firestore update before UI refresh
    await Future.delayed(const Duration(milliseconds: 200));

    //  Force UI update
    setState(() {});
  }
}
