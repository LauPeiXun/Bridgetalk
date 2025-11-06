import 'package:bridgetalk/application/controller/sos/sos_controller.dart';
import 'package:bridgetalk/data/models/user_model.dart';
import 'package:bridgetalk/presentation/screens/chat/chat_lobby_screen.dart';

import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';

class ChildSOSAlertScreen extends StatefulWidget {
  const ChildSOSAlertScreen({super.key});

  @override
  State<ChildSOSAlertScreen> createState() => _ChildSOSAlertScreenState();
}

class _ChildSOSAlertScreenState extends State<ChildSOSAlertScreen> {
  String? selectedRecipient;
  String? selectedMood;
  bool isSelectingMood = false;
  bool isTypingMessage = false;
  bool isFirstPage = true;
  bool isLoading = true;

  UserModel? currentUser;

  TextEditingController moodController = TextEditingController();
  SosController sosController = SosController();

  int currentLength = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void navigateToConfirmation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ConfirmationScreen(
              recipient: selectedRecipient!,
              mood: selectedMood!,
              message: moodController.text.trim(),
            ),
      ),
    );
  }

  Future<void> getUserData() async {
    UserModel? user = await sosController.getUserData();
    setState(() {
      currentUser = user;
    });
    if (currentUser?.uid != null) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 3),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ChatLobbyScreen()),
                );
              }
            },
          ),
        ),
        backgroundColor: Colors.orange.shade100,
        elevation: 0,
      ),
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
          //child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/sosImage.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    "Feeling stressed or down?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Don't hesitate to seek help from your parents!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, thickness: 1, height: 1),
                  const SizedBox(height: 24),

                  if (currentUser?.motherId != null ||
                      currentUser?.fatherId != null) ...[
                    Text(
                      isTypingMessage
                          ? "Type something..."
                          : isSelectingMood
                          ? "How are you feeling?"
                          : "Choose Recipient",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isTypingMessage)
                      _buildMoodTextBox(
                        moodController,
                        'What is making you feel this way?',
                      )
                    else if (isSelectingMood)
                      _buildMoodSelection()
                    else
                      _buildRecipientSelection(),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        isFirstPage
                            ? _buildActionButton(
                              "Cancel",
                              Colors.grey.shade300,
                              () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatLobbyScreen(),
                                  ),
                                );
                              },
                            )
                            : _buildActionButton(
                              "Back",
                              Colors.grey.shade300,
                              () {
                                setState(() {
                                  if (isTypingMessage) {
                                    isTypingMessage = false;
                                  } else if (isSelectingMood) {
                                    isSelectingMood = false;
                                  }
                                });
                              },
                            ),

                        _buildActionButton("Continue", Colors.orange, () {
                          setState(() {
                            isFirstPage = false;
                          });
                          if (!isSelectingMood) {
                            if (selectedRecipient != null) {
                              setState(() {
                                isSelectingMood = true;
                              });
                            } else {
                              _showError("Please select a recipient first.");
                            }
                          } else if (!isTypingMessage) {
                            if (selectedMood != null) {
                              setState(() {
                                isTypingMessage = true;
                              });
                            } else {
                              _showError("Please select how you feel.");
                            }
                          } else {
                            navigateToConfirmation();
                          }
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTypingMessage
                          ? "Please share what you're feeling"
                          : isSelectingMood
                          ? "Choose your current feeling"
                          : "Choose the recipient who you want to send",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!isLoading &&
                      currentUser?.motherId == null &&
                      currentUser?.fatherId == null) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "No Connection Detected 🌟\nGo to the Spark tab and connect with your loved ones!",
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      //),
      //bottomNavigationBar: CustomNavBar(currentIndex: 5),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRecipientSelection() {
    setState(() {
      isFirstPage = true;
    });
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (currentUser != null && currentUser!.fatherId != null) ...[
              _buildRecipientButton(
                'Father',
                Image.asset(
                  'assets/images/fatherImage.png',
                  width: 32,
                  height: 32,
                ),
              ),
            ],

            if (currentUser != null && currentUser!.motherId != null) ...[
              _buildRecipientButton(
                'Mother',
                Image.asset(
                  'assets/images/motherImage.png',
                  width: 32,
                  height: 32,
                ),
              ),
            ],
            if (currentUser != null &&
                currentUser!.motherId != null &&
                currentUser!.fatherId != null) ...[
              _buildRecipientButton(
                'Both',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/fatherImage.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/images/motherImage.png',
                      width: 32,
                      height: 32,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMoodSelection() {
    return Column(
      children: [
        _buildMoodButton('Stressed', 'assets/icons/stressed.png'),
        const SizedBox(height: 16),
        _buildMoodButton('Depressed', 'assets/icons/depressed.png'),
      ],
    );
  }

  Widget _buildMoodTextBox(TextEditingController controller, String hintText) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        TextField(
          controller: controller,
          maxLines: null,
          maxLength: 100,
          onChanged: (value) {
            setState(() {
              currentLength = value.length;
            });
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            counterText: "",
            contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 30),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Text(
            "$currentLength/100",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientButton(String label, Widget iconWidget) {
    final isSelected = selectedRecipient == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRecipient = label;
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.275,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color.fromARGB(255, 245, 189, 106)
                  : Colors.transparent,
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 40, child: iconWidget),
              const SizedBox(height: 10),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(String label, String imagePath) {
    final isSelected = selectedMood == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = label;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color.fromARGB(255, 245, 189, 106)
                  : Colors.transparent,
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 50, height: 50),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color:
                  (label == "Back" || label == "Cancel")
                      ? Colors.black
                      : Colors.white,

              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class ConfirmationScreen extends StatelessWidget {
  final String recipient;
  final String mood;
  final String message;

  ConfirmationScreen({
    super.key,
    required this.recipient,
    required this.mood,
    required this.message,
  });

  SosController sosController = SosController();
  late bool isSuccess;

  Future<void> sendSOSTestNotification(BuildContext context) async {
    isSuccess = await sosController.sendSOSNotification(
      recipient: recipient,
      mood: mood,
      message: message,
    );

    if (isSuccess) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/success.png',
                      height: 100,
                      width: 100,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      'Success !',
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),

                    Text(
                      'Help is on the way – your parent knows you’re feeling $mood.',
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatLobbyScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.orange.shade300,
                      ),
                      child: const Text(
                        'Back to Lobby',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    } else {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Failed', style: TextStyle(color: Colors.red)),
              content: Text(
                'Failed to send SOS notification. Please try again.',
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.justify,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 3),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChatLobbyScreen()),
              );
            },
          ),
        ),
        backgroundColor: Colors.orange.shade100,
        elevation: 0,
      ),
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
          //child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/sosImage.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    "Feeling stressed or down?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Don't hesitate to seek help from your parents!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, thickness: 1, height: 1),
                  const SizedBox(height: 24),
                  const Text(
                    "Confirm to send?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoBox("Recipient", recipient),
                  const SizedBox(height: 12),
                  _buildInfoBox("Mood Status", "Feeling $mood"),
                  const SizedBox(height: 12),
                  (message.isNotEmpty)
                      ? _buildInfoBox("More Information", message)
                      : SizedBox.shrink(),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        "Back",
                        Colors.grey.shade300,
                        () {
                          Navigator.of(context).pop();
                        },
                      ),

                      _buildActionButton(context, "Send", Colors.orange, () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      //),
      //bottomNavigationBar: CustomNavBar(currentIndex: 5),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onPressed();

          if (label == "Send") {
            sendSOSTestNotification(context);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color:
                  (label == "Back" || label == "Cancel")
                      ? Colors.black
                      : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
