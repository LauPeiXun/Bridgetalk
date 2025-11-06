import 'package:bridgetalk/application/controller/user_profile/user_profile_controller.dart';
import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';
import 'package:bridgetalk/data/models/parent_link_model.dart';
import 'package:bridgetalk/application/controller/connection/parent_link_controller.dart';
import 'dart:async';

import 'package:bridgetalk/presentation/widgets/others/spark_point_help_dialog.dart';

class ParentLinkScreen extends StatefulWidget {
  const ParentLinkScreen({super.key});

  @override
  State<ParentLinkScreen> createState() => _ParentLinkScreenState();
}

class _ParentLinkScreenState extends State<ParentLinkScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _currentUsername;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  List<ParentLinkModel> _connections = [];
  bool _showSearch = false;
  List<Map<String, dynamic>> _sentRequests = [];
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final ParentLinkController parentLinkController = ParentLinkController();

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing ParentLinkScreen');
    _initializeData();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
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

  Future<void> _initializeData() async {
    try {
      await _loadUserDataAndConnections();
      if (_currentUsername != null) {
        await _loadRequests();
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error initializing data: $e')));
      }
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

  Future<void> _loadUserDataAndConnections() async {
    try {
      debugPrint('Loading user data and connections');
      final userData = await parentLinkController.loadUserData();
      if (userData != null) {
        debugPrint('User data found: ${userData['username']}');
        if (!mounted) return;
        setState(() {
          _currentUsername = userData['username'] as String?;
        });
      } else {
        debugPrint('User data not found');
        throw Exception('User data not found');
      }

      final connections = await parentLinkController.loadConnections();
      debugPrint('Found ${connections.length} connections');

      if (!mounted) return;
      setState(() {
        _connections = connections;
        _connections.sort((a, b) => b.sparkPoint.compareTo(a.sparkPoint));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading connections: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading connections: $e')),
        );
      }
      rethrow;
    }
  }

  Future<void> _loadRequests() async {
    try {
      final sentRequests = await parentLinkController.loadSentRequests();

      final receivedRequests =
          await parentLinkController.loadReceivedRequests();

      if (!mounted) return;

      setState(() {
        _sentRequests = sentRequests;
        _receivedRequests = receivedRequests;
      });
      debugPrint(
        'Loaded ${_sentRequests.length} sent requests and ${_receivedRequests.length} received requests',
      );
    } catch (e) {
      debugPrint('Error loading requests: $e');
      rethrow;
    }
  }

  Future<void> _searchUsers(String query) async {
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
      final results = await parentLinkController.searchUsers(
        query,
        _currentUsername,
        _connections,
        _sentRequests,
      );

      if (results.isEmpty && query.length >= 3) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No available child users found matching your search',
            ),
          ),
        );
      }

      setState(() => _searchResults = results);
    } catch (e, stackTrace) {
      debugPrint('Error searching users: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching for users')),
      );
    }
  }

  Future<void> _handleRequest(
    String fromUserId,
    String senderUsername,
    bool accept,
  ) async {
    try {
      if (accept) {
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildConfirmationDialog(senderUsername),
        );

        if (confirmed != true) {
          return;
        }
      }

      await parentLinkController.handleRequest(
        fromUserId: fromUserId,
        accept: accept,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Connection request accepted from $senderUsername'
                : 'Connection request rejected',
          ),
          backgroundColor: accept ? Colors.green : null,
        ),
      );

      setState(() {
        _connections = [];
        _searchResults = [];
        _sentRequests = [];
        _receivedRequests = [];
      });

      _loadUserDataAndConnections();
      _loadRequests();
    } catch (e) {
      debugPrint('Error handling request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await parentLinkController.cancelRequest(requestId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled successfully')),
      );
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling request: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendRequest(String childUsername) async {
    try {
      Navigator.pop(context);
      await parentLinkController.sendRequest(childUsername: childUsername);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );

      _loadRequests();
    } catch (e) {
      debugPrint('Error sending request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: ${e.toString()}')),
      );
    }
  }

  Widget _buildConfirmationDialog(String username) {
    int countdown = 5;
    bool canConfirm = false;
    Timer? timer;

    void startTimer(VoidCallback update) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (countdown > 0) {
          countdown--;
          update();
          if (countdown == 0) {
            canConfirm = true;
            timer?.cancel();
          }
        } else {
          timer?.cancel();
        }
      });
    }

    return StatefulBuilder(
      builder: (context, setState) {
        if (timer == null) {
          startTimer(() => setState(() {}));
        }

        return AlertDialog(
          title: const Text('Confirm Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to connect with $username?'),
              const SizedBox(height: 16),
              Text(
                'Please wait $countdown seconds...',
                style: TextStyle(
                  color: canConfirm ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                timer?.cancel();
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  canConfirm
                      ? () {
                        timer?.cancel();
                        Navigator.of(context).pop(true);
                      }
                      : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  BoxShadow getFireGlowEffect(int sparkPoint) {
    if (sparkPoint >= 300) {
      return const BoxShadow(
        color: Colors.redAccent,
        blurRadius: 25,
        spreadRadius: 3,
      );
    } else if (sparkPoint >= 200) {
      return const BoxShadow(
        color: Colors.orange,
        blurRadius: 25,
        spreadRadius: 3,
      );
    } else if (sparkPoint >= 100) {
      return const BoxShadow(
        color: Colors.amberAccent,
        blurRadius: 15,
        spreadRadius: 2,
      );
    } else if (sparkPoint >= 50) {
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
    return StreamBuilder<List<ParentLinkModel>>(
      stream: parentLinkController.streamConnections(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final connections = snapshot.data!;
        connections.sort((a, b) => b.sparkPoint.compareTo(a.sparkPoint));
        if (connections.isEmpty) {
          return const Text("No connections found.");
        }

        return Column(
          children:
              connections.map((connection) {
                final sparkPoint = connection.sparkPoint;
                final username = connection.childUsername ?? 'Unknown';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                      const SizedBox(width: 20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopNav(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16.0,
                          right: 16,
                          left: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Connections',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showBottomSheet(context),
                                      child: Image.asset(
                                        'assets/images/wish-list.png',
                                        width: 25,
                                        height: 25,
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(
                                        Icons.help_outline,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        showSparkPointHelpBottomSheet(context);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Spark Section
                            if (_connections.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildConnectionsList(),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // Sent Requests Section
                            if (_sentRequests.isNotEmpty) ...[
                              const Text(
                                'Sent Requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sentRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _sentRequests[index];
                                  final toUsername =
                                      request['receiverUsername'] ??
                                      request['to'];

                                  return Card(
                                    color: Colors.white,
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      title: Text('To : $toUsername'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed:
                                                () => _cancelRequest(
                                                  request['id'],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],

                            const SizedBox(height: 10),

                            // Received Requests Section
                            if (_receivedRequests.isNotEmpty) ...[
                              const Text(
                                'Received Requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _receivedRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _receivedRequests[index];
                                  return Card(
                                    color: Colors.white,
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      title: Text(request['senderUsername']),
                                      subtitle: const Text('Child Request'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check),
                                            onPressed:
                                                () => _handleRequest(
                                                  request['senderId'],
                                                  request['senderUsername'],
                                                  true,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed:
                                                () => _handleRequest(
                                                  request['senderId'],
                                                  request['senderUsername'],
                                                  false,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
        ),
      ),

      bottomNavigationBar: CustomNavBar(currentIndex: 3),
    );
  }

  void _showBottomSheet(BuildContext context) {
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
                // Drag indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Find Your Precious Ones',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => _searchUsers(value),
                ),
                const SizedBox(height: 10),
                // Scrollable content
                if (_searchResults.isNotEmpty) ...[
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
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
                              onPressed: () => _sendRequest(user['username']),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.greenAccent.shade700,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Send Request'),
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
                        style: TextStyle(color: Colors.black, fontSize: 13),
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
}
