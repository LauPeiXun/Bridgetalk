// lib/signup_screen.dart
import 'package:flutter/material.dart';

import 'package:bridgetalk/application/controller/auth/sign_up_controller.dart';

import 'package:bridgetalk/presentation/widgets/general_widgets/custom_toast.dart';
import 'package:bridgetalk/presentation/screens/auth/login_screen.dart';
import 'package:bridgetalk/presentation/widgets/general_widgets/pop_up_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  String? _selectedGender, _usernameErrorText;

  final SignUpController _signUpController = SignUpController();

  /// role selected by user: either `'Parent'` or `'Child'`
  String _selectedRole = '';

  bool _isPasswordVisible = false;

  FocusNode usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    usernameFocusNode.addListener(() {
      if (!usernameFocusNode.hasFocus) {
        _checkDuplicateUsername();
      }
    });
  }

  /* -------------------------- validation helpers ------------------------- */
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _checkDuplicateUsername() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) return;

    bool isDuplicate = await _signUpController.isUsernameDuplicate(username);
    setState(() {
      _usernameErrorText = isDuplicate ? 'Username already taken' : null;
    });
  }

  /* -------------------------- firebase submission ------------------------ */
  Future<void> _submitData() async {
    FocusScope.of(context).unfocus();

    if (_selectedRole.isEmpty) {
      ToastHelper.showError("Please choose Parent or Child");
      return;
    }

    final isDuplicate = await _signUpController.isUsernameDuplicate(
      usernameController.text.trim(),
    );

    if (isDuplicate) {
      setState(() {
        _usernameErrorText = 'Username already taken';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      String username = usernameController.text.trim();

      final result = await _signUpController.registerUser(
        email: email,
        password: password,
        username: username,
        role: _selectedRole,
        gender: _selectedGender!,
      );

      if (result == null) {
        if (mounted) {
          PopUpDialog(
            imagePath: 'assets/images/forgot-password-animation.gif',
            title: 'Account Created',
            message: 'Your account is ready. Let the connection begin!',
            onDialogClosed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ).show(context);
        }
      } else {
        ToastHelper.showError("Sign‑up failed: $result");
      }
    } else {
      ToastHelper.showError("Please fill in all fields correctly.");
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
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ),
        backgroundColor: Colors.orange.shade100,
      ),

      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _signUpPageTitle(),
                    const SizedBox(height: 15),
                    _registerForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signUpPageTitle() {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/icon.png',
              height: 100,
              width: 100,
            ),
          ),
        ),

        const SizedBox(height: 10),
        const Text(
          'Create Account',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'Begin building a deeper family connection now!',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _registerForm() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roleTile(role: 'Parent', icon: Icons.family_restroom),
            const SizedBox(width: 16),
            _roleTile(role: 'Child', icon: Icons.child_care),
          ],
        ),
        const SizedBox(height: 15),

        /* --------------------------- text fields ------------------------- */
        TextFormField(
          controller: usernameController,
          focusNode: usernameFocusNode,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.person_outline),
            errorText: _usernameErrorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange),
            ),
          ),
          buildCounter: (
            context, {
            required int currentLength,
            required int? maxLength,
            required bool isFocused,
          }) {
            return Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: Text(
                '$currentLength/$maxLength',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          },
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter a username'
                      : null,
        ),

        const SizedBox(height: 15),

        DropdownButtonFormField<String>(
          value: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          validator:
              (value) => value == null ? 'Please select your gender' : null,
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items:
              ['Male', 'Female'].map((gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
        ),

        const SizedBox(height: 15),

        TextFormField(
          controller: emailController,
          validator: _validateEmail,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
        const SizedBox(height: 15),

        TextFormField(
          controller: passwordController,
          validator: _validatePassword,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed:
                  () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange),
            ),
          ),
        ),

        const SizedBox(height: 20),

        /* -------------------------- sign‑up button ----------------------- */
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        /* ----------------------- go‑to login link ------------------------ */
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Already have an account?"),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleTile({required String role, required IconData icon}) {
    final bool isPicked = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPicked ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 2),
          boxShadow: [
            if (isPicked)
              BoxShadow(
                color: Colors.orangeAccent.withAlpha(100),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: isPicked ? Colors.white : Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPicked ? Colors.white : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
