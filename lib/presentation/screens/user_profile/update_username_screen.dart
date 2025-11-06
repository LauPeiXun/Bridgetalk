// lib/login_screen.dart
import 'package:bridgetalk/application/controller/user_profile/update_username_controller.dart';
import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';
import 'package:bridgetalk/presentation/screens/user_profile/user_profile_screen.dart';

class UpdateUsernameScreen extends StatefulWidget {
  const UpdateUsernameScreen({super.key});

  @override
  State<UpdateUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<UpdateUsernameScreen> {
  final UpdateUsernameController updateUsernameController =
      UpdateUsernameController();
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  String? _usernameErrorText;

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _checkDuplicateUsername();
      }
    });

    Future.delayed(Duration(milliseconds: 100), () {
      // ignore: use_build_context_synchronously
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  Future<void> _checkDuplicateUsername() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) return;

    bool isDuplicate = await updateUsernameController.isUsernameDuplicate(
      username,
    );
    setState(() {
      _usernameErrorText = isDuplicate ? 'Username already taken' : null;
    });
  }

  // Update the username
  Future<void> _submitData() async {
    FocusScope.of(context).unfocus();

    final isDuplicate = await updateUsernameController.isUsernameDuplicate(
      usernameController.text.trim(),
    );

    if (isDuplicate) {
      setState(() {
        _usernameErrorText = 'Username already taken';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        await updateUsernameController.updateUsername(
          usernameController.text.trim(),
        );

        if (mounted) {
          PopUpDialog(
            imagePath: 'assets/images/check.png',
            title: 'Username Updated Successfully',
            message: '',
            onDialogClosed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ).show(context);
        }
      } catch (e) {
        ToastHelper.showError("Operation Unsuccessfully!");
      }
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
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ),
        title: Text("Update Username"),
        centerTitle: false,
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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/office-material.png',
                              height: 120,
                              width: 120,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Update Username',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: usernameController,
                        focusNode: focusNode,
                        onChanged: (value) {
                          setState(() {});
                        },
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'New Username',
                          errorText: _usernameErrorText,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                        ),
                        buildCounter: (
                          context, {
                          required currentLength,
                          maxLength,
                          required isFocused,
                        }) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 5.0,
                              right: 5.0,
                            ),
                            child: Text(
                              '$currentLength/$maxLength',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: _submitData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Username',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
