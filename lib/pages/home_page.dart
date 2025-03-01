import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/shopping_item.dart';
import 'compare_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  final List<String> _categories = [
    'Frozen Foods',
    'Dairy',
    'Meat',
    'Vegetables',
    'Other',
  ];

  void _showAddItemDialog({ShoppingItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    String? selectedCategory = item?.category; //  Default to null
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Add New Item' : 'Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle:
                      TextStyle(color: theme.textTheme.bodyLarge?.color),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle:
                      TextStyle(color: theme.textTheme.bodyLarge?.color),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                items: _categories.map((String cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (String? newVal) {
                  if (newVal != null) {
                    setState(() {
                      selectedCategory = newVal; //  Store selection
                    });
                  }
                },
                validator: (value) => value == null
                    ? 'Please select a category'
                    : null, //  Ensure selection
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
                final name = nameController.text.trim();

                if (name.isNotEmpty && selectedCategory != null) {
                  if (item == null) {
                    final newItem = ShoppingItem(
                      id: '',
                      name: name,
                      category: selectedCategory ?? '',
                      isChecked: false,
                    );
                    await _dbService.saveShoppingItem(newItem);
                  } else {
                    await _dbService.updateShoppingItemDetails(
                      item.id,
                      name,
                      selectedCategory ?? '',
                    );
                  }
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please enter a name and select a category')),
                  );
                }
              },
              child: Text(item == null ? 'Add Item' : 'Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await _authService.signOut();
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
          'Grocery Guru',
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
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Keeps it compact
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    theme.brightness == Brightness.dark
                        ? 'assets/GroceryGuru_light.png' // Dark mode icon
                        : 'assets/GroceryGuru_dark.png', // Light mode icon
                    height: 40, // Adjust size as needed
                    width: 40,
                  ),
                  const SizedBox(width: 12), // Space between icon and text
                  Text(
                    'Grocery Guru',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black // Dark mode text color
                          : Colors.white, // Light mode text color
                      fontFamily: 'RobotoSerif',
                      fontWeight: FontWeight.bold,
                      fontSize: 26, // Adjust text size
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Comparer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ComparePage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<ShoppingItem>>(
        stream: _dbService.streamShoppingItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('No items yet. Tap "Add new item" to get started!'),
            );
          }

          final Map<String, List<ShoppingItem>> categoryMap = {};
          for (var item in items) {
            categoryMap.putIfAbsent(item.category, () => []);
            categoryMap[item.category]!.add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: categoryMap.entries.map((entry) {
              final category = entry.key;
              final catItems = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      category.toUpperCase(),
                      style: theme.textTheme.bodyLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...catItems.map((item) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        leading: Checkbox(
                          value: item.isChecked,
                          onChanged: (bool? checked) {
                            _dbService.updateShoppingItem(
                                item.id, checked ?? false);
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddItemDialog(item: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _dbService.deleteShoppingItem(item.id),
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
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter, // Ensures the button is centred
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20), // Adjust for spacing
          child: FloatingActionButton.extended(
            onPressed: _showAddItemDialog,
            backgroundColor:
                Theme.of(context).colorScheme.primary, // Uses theme color
            foregroundColor: Theme.of(context)
                .colorScheme
                .onPrimary, // Ensures text is visible
            icon: const Icon(Icons.add),
            label: const Text('Add new item'),
          ),
        ),
      ),
    );
  }
}
