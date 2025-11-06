import 'package:flutter/material.dart';
import 'package:bridgetalk/application/controller/navigation/nav_bar_controller.dart';
import 'package:bridgetalk/presentation/screens/child_sos_alert/child_sos_alert_screens.dart';

class CustomTopNav extends StatefulWidget implements PreferredSizeWidget {
  const CustomTopNav({super.key});

  @override
  _CustomTopNavState createState() => _CustomTopNavState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomTopNavState extends State<CustomTopNav> {
  final NavBarController navBarController = NavBarController();
  String? userRole, todayMood, todayEmoji;

  @override
  void initState() {
    super.initState();
    _loadUserRole();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      navBarController.loadTodayMood(context);
    });
  }

  Future<void> _loadUserRole() async {
    userRole = await navBarController.getUserRole();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: null,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.orange.shade100,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset('assets/icons/BridgeTalk.png', height: 30),
          const SizedBox(width: 8),
          const Text(
            'BridgeTalk',
            style: TextStyle(
              color: Colors.black,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (userRole == 'Child')
          Padding(
            padding: const EdgeInsets.only(right: 8.5),
            child: Align(
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(Icons.sos, color: Colors.red, size: 33.5),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChildSOSAlertScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }
}
