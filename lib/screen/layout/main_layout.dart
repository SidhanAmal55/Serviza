import 'package:flutter/material.dart';
import 'package:myapp/screen/customers/customers_screen%20.dart';
import 'package:myapp/screen/invoice/invoice_listview_page.dart';
import 'package:myapp/widgets/%20custom_sidebar.dart';
import 'package:myapp/widgets/top_bar.dart';
import '../home_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> pages = [
    const HomeScreen(),
    const CustomersScreen(),
    Center(child: Text('Coming Soon')),
    const InvoiceListScreen(),
  ];

  void onSidebarItemTap(int index) {
    setState(() {
      selectedIndex = index;
      if (isMobile(context)) Navigator.pop(context); // Close drawer on mobile
    });
  }

  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    const Color coffeeLight = Color(0xFFF5E6D3);

    final isPhone = isMobile(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: coffeeLight, // Set background to coffee light
      drawer:
          isPhone
              ? Drawer(
                child: CustomSidebar(
                  selectedIndex: selectedIndex,
                  onItemSelected: onSidebarItemTap,
                ),
              )
              : null,
      body: SafeArea(
        child:
            isPhone
                ? Column(
                  children: [
                    TopBar(
                      isMobile: isPhone,
                      openDrawer: () => scaffoldKey.currentState?.openDrawer(),
                    ),
                    Expanded(child: pages[selectedIndex]),
                  ],
                )
                : Row(
                  children: [
                    CustomSidebar(
                      selectedIndex: selectedIndex,
                      onItemSelected: onSidebarItemTap,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          TopBar(
                            isMobile: isPhone,
                            openDrawer: () {}, // No drawer on desktop
                          ),
                          Expanded(child: pages[selectedIndex]),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
