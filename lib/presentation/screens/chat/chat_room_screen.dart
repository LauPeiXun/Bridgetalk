import 'package:flutter/material.dart';

import 'package:bridgetalk/application/controller/user_profile/user_profile_controller.dart';
import 'package:bridgetalk/application/controller/chat/chat_room_controller.dart';

import 'package:bridgetalk/data/models/user_model.dart';

import 'package:bridgetalk/presentation/utils/profanity_filter.dart';
import 'package:bridgetalk/presentation/utils/mood_color_utils.dart';

import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class ChatRoom extends StatefulWidget {
  final String receiverId;
  final String emoji;
  final String receiverMood;
  final String username;
  final String userRole;

  const ChatRoom({
    super.key,
    required this.receiverId,
    required this.emoji,
    required this.receiverMood,
    required this.username,
    required this.userRole,
  });

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ChatRoomController _chatRoomController = ChatRoomController();
  final UserProfileController _userProfileController = UserProfileController();
  final ScrollController _scrollController = ScrollController();

  // Keys & Variables
  final Map<String, GlobalKey> _messageKeys = {};
  final ValueNotifier<String?> _warningMessage = ValueNotifier<String?>(null);
  List<Color> colors = [];
  String? senderId, imageUrl;
  bool isLoading = true;
  late FocusNode _messageFocusNode;

  // Initialize the chat room
  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _messageFocusNode = FocusNode();

    colors = MoodColorUtil.getMoodColor(widget.emoji);

    KeyboardVisibilityController().onChange.listen((bool visible) {
      if (visible) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          scrollDown();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));

      UserModel? userModel = await _chatRoomController.getCurrentUserModel();

      setState(() {
        senderId = userModel?.uid ?? '';
        isLoading = false;
      });
    });

    if (isLoading) {
      Future.delayed(const Duration(milliseconds: 450), () {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          scrollDown();
        });
      });
    }
  }

  Future<void> sentimentAnalyseAndWordSuggestion(
    BuildContext context,
    String message,
    List<String> profanityWordContain,
  ) async {
    _messageFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/BridgeTalk.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Oops! Profanity Word detected.",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "We noticed some words that might sound a bit harsh. Here's a kinder way to express your message.",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 8),
                Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            ),
          ),
        );
      },
    );

    final result = await _chatRoomController.generateProfanityWordResult(
      message,
      widget.receiverMood,
      widget.emoji,
      widget.userRole,
      profanityWordContain,
    );

    final suggestion = await _chatRoomController
        .generateProfanityWordSuggestion(
          message,
          widget.receiverMood,
          widget.emoji,
          widget.userRole,
          profanityWordContain,
        );

    if (result != null &&
        result.isNotEmpty &&
        suggestion != null &&
        suggestion.isNotEmpty) {
      Navigator.of(context).pop();
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.65,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/BridgeTalk.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Oops! Profanity Word detected.",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We noticed some words that might sound a bit harsh. Here's a kinder way to express your message.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result,
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.justify,
                        ),
                        Text(
                          "Suggestion Revised Message:",
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          suggestion,
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.justify,
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _messageController.text = suggestion.trim();
                              _warningMessage.value = null;
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Use This Suggestion',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // Dispose of the controllers
  @override
  void dispose() {
    _messageFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    try {
      String? url = await _userProfileController.getProfileImageUrl(
        widget.receiverId,
      );
      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      setState(() {
        imageUrl = null;
      });
    }
  }

  // Send message when the enter key is pressed
  void _sendMessage() async {
    String message = _messageController.text.trim();
    final profanityResult = ProfanityWordFilter.filterText(message);

    if (profanityResult["isProfane"]) {
      sentimentAnalyseAndWordSuggestion(
        context,
        message,
        profanityResult["profanityWordContain"],
      );
    } else {
      if (message.isNotEmpty) {
        await _chatRoomController.sendMessage(
          message: message,
          recipientId: widget.receiverId,
        );
        _messageController.clear();
      }
    }

    Future.delayed(Duration(milliseconds: 350), () {
      scrollDownInputSend();
    });
  }

  // Scroll to the bottom when messages fully loaded
  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController
            .animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            )
            .then((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent + 600,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            });
      }
    });
  }

  // This is used when the keyboard is open and the user sends a message
  void scrollDownInputSend() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.linear,
      );
    });
  }

  // Helper method to restore keyboard focus if it was previously focused
  void _restoreKeyboardFocusIfNeeded(bool wasKeyboardFocused) {
    if (wasKeyboardFocused) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_messageFocusNode.canRequestFocus) {
          _messageFocusNode.requestFocus();
        }
      });
    }
  }

  // Function to show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String messageId) {
    // Check if the text field has focus
    bool wasKeyboardFocused = _messageFocusNode.hasFocus;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restoreKeyboardFocusIfNeeded(wasKeyboardFocused);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _chatRoomController.deleteMessage(widget.receiverId, messageId);
                Navigator.of(context).pop();
                _restoreKeyboardFocusIfNeeded(wasKeyboardFocused);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: colors[0],
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 12,
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors[0], Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child:
                  isLoading
                      ? const Center(child: Text("Loading messages..."))
                      : _buildMessageList(),
            ),
            _buildUserInput(),
          ],
        ),
      ),
    );
  }

  // Date separator widget
  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // Build the list of messages
  Widget _buildMessageList() {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollDown());
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: StreamBuilder(
          stream: _chatRoomController
              .getChatRoomMessages(widget.receiverId, null)
              .asStream()
              .asyncExpand((stream) => stream),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Text("Loading messages..."));
            }

            final messages = snapshot.data!.docs;

            SchedulerBinding.instance.addPostFrameCallback((_) {
              scrollDown();
            });

            // Process messages to include date separators
            List<Widget> messageWidgets = [];
            String? currentDate;
            String? messageTime;

            for (int i = 0; i < messages.length; i++) {
              final message = messages[i];
              final messageData = message.data() as Map<String, dynamic>;
              final messageId = message.id;

              // Extract timestamp and convert to date string
              if (messageData.containsKey('timestamp')) {
                String messageDate;
                var timestamp = messageData['timestamp'];

                // Parse the timestamp string
                RegExp regex = RegExp(r'seconds=(\d+)');
                Match? match = regex.firstMatch(timestamp);
                if (match != null) {
                  int seconds = int.parse(match.group(1)!);
                  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                    seconds * 1000,
                  );

                  messageTime = DateFormat('hh:mm a').format(dateTime);
                  messageDate = DateFormat('yyyy-MM-dd').format(dateTime);
                } else {
                  DateTime now = DateTime.now();
                  messageDate = now.toString().split(' ')[0];
                  messageTime = DateFormat('hh:mm a').format(now);
                }

                // Check if date changed
                if (currentDate != messageDate) {
                  currentDate = messageDate;

                  final now = DateTime.now();
                  String todayString = DateFormat('yyyy-MM-dd').format(now);

                  String displayDate =
                      (messageDate == todayString) ? "Today" : messageDate;

                  messageWidgets.add(_buildDateSeparator(displayDate));
                }
              }

              // Add the message
              final isLastMessage = i == messages.length - 1;
              messageWidgets.add(
                _buildMessageItem(
                  messageId: messageId,
                  messageData: messageData,
                  messageTime: messageTime,
                  isLastMessage: isLastMessage,
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: messageWidgets,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build individual message item
  Widget _buildMessageItem({
    required String messageId,
    required Map<String, dynamic> messageData,
    required messageTime,
    required bool isLastMessage,
  }) {
    if (!_messageKeys.containsKey(messageId)) {
      _messageKeys[messageId] = GlobalKey();
    }

    bool isCurrentUser = messageData['senderId'] == senderId;

    Alignment alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      key: isLastMessage ? _messageKeys[messageId] : null,
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () {
          if (isCurrentUser) {
            _showDeleteConfirmation(context, messageId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          margin:
              isCurrentUser
                  ? const EdgeInsets.only(left: 50, right: 5, bottom: 10)
                  : const EdgeInsets.only(left: 5, right: 50, bottom: 10),
          child: Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child:
                    (!isCurrentUser && imageUrl == null)
                        ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: colors[2], width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/profileImage.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                        : (!isCurrentUser && imageUrl != null)
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/profileImage.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                        : Container(),
              ),

              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: colors[2], width: 1),
                  borderRadius: BorderRadius.only(
                    topLeft:
                        isCurrentUser
                            ? const Radius.circular(14)
                            : const Radius.circular(0),
                    topRight:
                        isCurrentUser
                            ? const Radius.circular(0)
                            : const Radius.circular(14),
                    bottomLeft: const Radius.circular(14),
                    bottomRight: const Radius.circular(14),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 235),
                  child: Text(
                    messageData['message'],
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.justify,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build user input field
  Widget _buildUserInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: _warningMessage,
            builder: (context, warning, child) {
              if (warning == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  warning,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: colors[2], width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      focusNode: _messageFocusNode,
                      controller: _messageController,
                      onChanged: (value) {
                        final profanityResult = ProfanityWordFilter.filterText(
                          value,
                        );
                        if (profanityResult["isProfane"]) {
                          _warningMessage.value = profanityResult["message"];
                        } else {
                          _warningMessage.value = null;
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                height: 48.0,
                width: 48.0,
                decoration: BoxDecoration(
                  color: colors[0],
                  border: Border.all(color: colors[2], width: 1),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: colors[2]),
                  onPressed: _sendMessage,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
