import 'package:flutter/material.dart';

class CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<String> menuItems = const [
    'Home',
    'Customers',
    'Items',
    'Invoices',
  ];

  @override
  Widget build(BuildContext context) {
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeLight = Color(0xFFF5E6D3);
    const Color coffeeAccent = Color(0xFF8D6E63);

    return Container(
      width: 150,
      color: coffeeDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: coffeeDark,
            child: const Text(
              'DASHBOARD', // Changed from 'MENU'
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Sidebar Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: coffeeAccent,
                  title: Text(
                    menuItems[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : coffeeLight,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                  ),
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
