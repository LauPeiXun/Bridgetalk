import 'package:bridgetalk/application/controller/user_profile/user_profile_controller.dart';
import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';
import 'package:bridgetalk/application/controller/connection/child_link_controller.dart';
import 'package:bridgetalk/data/models/child_link_model.dart';
import 'dart:async';

import 'package:bridgetalk/presentation/widgets/others/spark_point_help_dialog.dart';
import 'package:flutter/foundation.dart';

class ChildLinkScreen extends StatefulWidget {
  const ChildLinkScreen({super.key});

  @override
  State<ChildLinkScreen> createState() => _ChildLinkScreenState();
}

class _ChildLinkScreenState extends State<ChildLinkScreen>
    with SingleTickerProviderStateMixin {
  String? _userRole;
  List<ChildLinkModel> _connections = [];
  ChildLinkModel? _fatherConnection;
  ChildLinkModel? _motherConnection;
  bool _isLoading = true;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final Map<String, int> sparkPoints = {};
  final ChildLinkController childLinkController = ChildLinkController();

  @override
  void initState() {
    super.initState();
    _loadUserDataAndConnections();
    _loadRequests();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      final sentRequests = await childLinkController.loadSentRequests();
      final receivedRequests = await childLinkController.loadReceivedRequests();

      if (!mounted) return;

      if (kDebugMode) {
        print(receivedRequests.length);
      }

      setState(() {
        _sentRequests = sentRequests;
        _receivedRequests = receivedRequests;
      });

      debugPrint(
        'Loaded ${_sentRequests.length} sent requests and ${_receivedRequests.length} received requests',
      );
    } catch (e) {
      debugPrint('Error loading requests: $e');
    }
  }

  Future<void> _refreshPage() async {
    setState(() {
      _connections = [];
      _searchResults = [];
      _sentRequests = [];
      _receivedRequests = [];
      _isLoading = false;
    });

    await _loadUserDataAndConnections();
    await _loadRequests();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _searchUsers(String query, String parentRole) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearch = false;
      });
      return;
    }

    setState(() {
      _showSearch = true;
    });

    try {
      debugPrint('Searching for parent users with query: $query');
      final results = await childLinkController.searchParentUsers(
        query,
        parentRole,
      );
      if (!mounted) return;

      setState(() {
        _searchResults = results;
      });

      if (results.isEmpty && query.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No parent users found matching your search'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching for users')),
      );
    }
  }

  Future<void> _sendConnectionRequest(
    String toUsername,
    String parentRole,
  ) async {
    try {
      await childLinkController.sendConnectionRequest(toUsername, parentRole);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request sent successfully')),
      );

      setState(() {
        _searchResults = [];
        _searchController.clear();
      });

      _loadRequests();
    } catch (e) {
      debugPrint('Error sending request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }

  Future<void> _loadUserDataAndConnections() async {
    try {
      debugPrint('Loading user data and connections');
      final userData = await childLinkController.loadUserData();
      if (userData != null) {
        debugPrint('User document found: ${userData['username']}');
        setState(() {
          _userRole = userData['role'] as String?;
        });
      } else {
        debugPrint('User document not found');
      }

      final connections = await childLinkController.loadConnections();
      debugPrint('Found ${connections.length} connections');

      // Reset parent connections
      setState(() {
        _fatherConnection = null;
        _motherConnection = null;
      });

      // Set father and mother connections
      for (var connection in connections) {
        final parentRole = connection.parentRole?.toString().toLowerCase();
        if (parentRole == 'father') {
          setState(() {
            _fatherConnection = connection;
          });
        }
        if (parentRole == 'mother') {
          setState(() {
            _motherConnection = connection;
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _connections = connections;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading connections: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading connections: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildConnectionBox(String title, ChildLinkModel? connection) {
    if (connection == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(26),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed:
                  _sentRequests.any(
                        (req) => req['parentRole'] == title.toLowerCase(),
                      )
                      ? null
                      : () {
                        _searchResults = [];
                        _searchController.clear();
                        _showSearch = false;
                        _showBottomSheet(context, title);
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade300,
                foregroundColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 15,
                ),
              ),
              child: const Text(
                'Add Connection',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void _showBottomSheet(BuildContext context, String parentRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Search input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for $parentRole',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _searchUsers(value, parentRole),
                ),
                const SizedBox(height: 10),
                // Search result list
                if (_searchResults.isNotEmpty) ...[
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final isRequestSent = _sentRequests.any(
                          (req) =>
                              (req['receiverUsername'] ?? req['to']) ==
                                  user['username'] &&
                              req['status'] == 'pending',
                        );

                        if (isRequestSent) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          color: Colors.white70,
                          margin: EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            leading: ClipOval(
                              child: buildProfileImage(user['id']),
                            ),
                            title: Text(user['username']),
                            trailing: TextButton(
                              onPressed: () {
                                _sendConnectionRequest(
                                  user['username'],
                                  parentRole,
                                );
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.orange.shade300,
                                foregroundColor: Colors.black87,
                              ),
                              child: const Text('Send Request'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                if (_showSearch && _searchResults.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        "No Result Found",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  final UserProfileController _userProfileController = UserProfileController();

  Widget buildProfileImage(String uid) {
    return FutureBuilder<String?>(
      future: _userProfileController.getProfileImageUrl(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While the URL is loading, show a loading indicator
          return ShimmerWidget.rectangular(width: 60, height: 60);
        } else if (snapshot.hasError) {
          // Handle error
          return Image.asset(
            'assets/images/profileImage.png',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          // If the image URL is available
          String imageUrl = snapshot.data!;
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: 60,
            height: 60,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Image.asset(
                'assets/images/profileImage.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/profileImage.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              );
            },
          );
        } else {
          // If no image URL found or data is null
          return Image.asset(
            'assets/images/profileImage.png',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopNav(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? Center(
                    child: const Text(
                      "Data is loading...",
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _refreshPage,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          if (_userRole?.toLowerCase() == 'child') ...[
                            _buildChildView(),
                          ] else if (_userRole?.toLowerCase() == 'parent')
                            ...[
            ] else if (_userRole == 'parent') ...[
                            _buildParentView(),
                          ],
                        ],
                      ),
                    ),
                  ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 3),
    );
  }

  Widget _buildChildView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connections With Guardians',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.grey),
                onPressed: () {
                  showSparkPointHelpBottomSheet(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 5),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              children: [
                _buildConnectionBox('Father', _fatherConnection),
                _buildConnectionBox('Mother', _motherConnection),
              ],
            ),
          ),
          if (_connections.isNotEmpty) ...[_buildConnectionsList()],
          if (_receivedRequests.isNotEmpty || _sentRequests.isNotEmpty) ...[
            const SizedBox(height: 3),
            _buildConnectionRequests(),
          ],
        ],
      ),
    );
  }

  Widget _buildParentView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_connections.isNotEmpty) ...[
            const Text(
              'My Connections',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            _buildConnectionsList(),
            _buildConnectionRequests(),
          ],
          const Text(
            'My Connections',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          _buildConnectionsList(),
          _buildConnectionRequests(),
        ],
      ),
    );
  }

  String getFireImagePath(int sparkPoint) {
    if (sparkPoint <= 20) return 'assets/images/fire/fire0.png';
    if (sparkPoint <= 50) return 'assets/images/fire/fire1.png';
    if (sparkPoint <= 100) return 'assets/images/fire/fire2.png';
    if (sparkPoint <= 150) return 'assets/images/fire/fire3.png';
    if (sparkPoint <= 200) return 'assets/images/fire/fire4.png';
    if (sparkPoint <= 250) return 'assets/images/fire/fire5.png';
    if (sparkPoint <= 300) return 'assets/images/fire/fire6.png';
    if (sparkPoint <= 350) return 'assets/images/fire/fire7.png';
    if (sparkPoint <= 400) return 'assets/images/fire/fire8.png';
    return 'assets/images/fire/fire8.png';
  }

  int getLevelFromSparkPoint(int sparkPoint) {
    if (sparkPoint <= 20) return 1;
    if (sparkPoint <= 50) return 2;
    if (sparkPoint <= 100) return 3;
    if (sparkPoint <= 150) return 4;
    if (sparkPoint <= 200) return 5;
    if (sparkPoint <= 250) return 6;
    if (sparkPoint <= 300) return 7;
    if (sparkPoint <= 350) return 8;
    if (sparkPoint <= 400) return 9;
    return 10;
  }

  BoxShadow getFireGlowEffect(int sparkPoint) {
    
    if (sparkPoint >= 300) {
      return const BoxShadow(
        color: Colors.orange,
        blurRadius: 25,
        spreadRadius: 3,
      );
    } else if (sparkPoint >= 200) {
      return const BoxShadow(
        color: Colors.amberAccent,
        blurRadius: 15,
        spreadRadius: 2,
      );
    } else if (sparkPoint >= 100) {
      return const BoxShadow(
        color: Colors.orangeAccent,
        blurRadius: 15,
        spreadRadius: 2,
      );
    } else {
      return const BoxShadow(
        color: Color.fromARGB(255, 235, 195, 133),
        blurRadius: 10,
        spreadRadius: 1,
      );
    }
  }

  Widget buildBouncingFireIcon(int sparkPoint) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [getFireGlowEffect(sparkPoint)],
        ),
        child: Image.asset(
          getFireImagePath(sparkPoint),
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildConnectionsList() {
    return StreamBuilder<List<ChildLinkModel>>(
      stream: childLinkController.streamConnections(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final connections = snapshot.data!;
        if (connections.isEmpty) {
          return const Text("No connections found.");
        }

        return Column(
          children:
              connections.map((connection) {
                final sparkPoint = connection.sparkPoint;
                final role = connection.parentRole?.toUpperCase() ?? 'Unknown';
                final username = connection.username ?? 'Unknown';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      buildBouncingFireIcon(sparkPoint),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Role: $role',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                LinearProgressIndicator(
                                  value: (sparkPoint / 500).clamp(0.01, 1.0),
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.deepOrange,
                                      ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Spark Points: $sparkPoint"),
                                Text(
                                  "Level ${getLevelFromSparkPoint(sparkPoint)}",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildConnectionRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_receivedRequests.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Received Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._receivedRequests.map(
            (request) => Card(
              color: Colors.white,
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                title: Text('From : ${request['senderUsername']}'),
                subtitle: Text(
                  'Role : ${request['parentRole']?.toString().toUpperCase() ?? 'Unknown'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => _handleRequest(request, true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _cancelRequest(request['id']),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_sentRequests.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Sent Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._sentRequests.map(
            (request) => Card(
              color: Colors.white,
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                title: Text('To : ${request['receiverUsername']}'),
                subtitle: Text(
                  'Role : ${request['parentRole']?.toString().toUpperCase() ?? 'Unknown'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _cancelRequest(request['id']),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleRequest(Map<String, dynamic> request, bool accept) async {
    try {
      if (accept) {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildConfirmationDialog(request),
        );

        if (confirmed != true) {
          return; // User cancelled or dialog was dismissed
        }
      }

      await childLinkController.handleRequest(request, accept);

      // Reload the requests and connections
      _loadRequests();
      _loadUserDataAndConnections();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${accept ? 'accepted' : 'rejected'}')),
      );
    } catch (e) {
      debugPrint('Error handling request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error handling request: $e')));
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await childLinkController.cancelRequest(requestId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled successfully')),
      );

      // Reload both requests and connections to update the UI
      _loadRequests();
      _loadUserDataAndConnections();
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cancelling request: $e')));
    }
  }

  Widget _buildConfirmationDialog(Map<String, dynamic> request) {
    return ConfirmationDialog(request: request);
  }
}

class ConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> request;

  const ConfirmationDialog({super.key, required this.request});

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  bool canConfirm = false;
  int countdown = 5;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown > 0) {
        setState(() {
          countdown--;
          if (countdown == 0) {
            canConfirm = true;
            timer?.cancel();
          }
        });
      } else {
        timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: const Text('Confirm Connection')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to establish a family connection with ${widget.request['senderUsername'] ?? widget.request['from']}?',
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.justify,
          ),

          if (countdown > 0) ...[
            const SizedBox(height: 10),
            Text(
              'You can confirm in $countdown seconds',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel Button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop(false);
                  },
                  style: ElevatedButton.styleFrom(
                    iconColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Confirm Button
              ElevatedButton(
                onPressed:
                    canConfirm
                        ? () {
                          timer?.cancel();
                          Navigator.of(context).pop(true);
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
