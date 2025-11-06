import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';
import 'package:bridgetalk/data/models/mood_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:bridgetalk/application/controller/user_profile/user_profile_controller.dart';

//Redirect Path
import 'package:bridgetalk/presentation/screens/user_profile/update_username_screen.dart';
import 'package:bridgetalk/presentation/screens/user_profile/update_password_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileController _userProfileController = UserProfileController();

  File? _imageFile;
  String? _imageUrl, todayEmoji, todayMood;
  bool _isUploading = false;
  List<Color> colors = [
    Colors.grey.shade100,
    Colors.grey.shade200,
    Colors.grey.shade400,
  ];
  bool _isMoodLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    setCurrentUserMood();
  }

  Future<void> setCurrentUserMood() async {
    MoodModel? userMood = await _userProfileController.getCurrentUserMood();
    if (userMood != null) {
      setState(() {
        todayEmoji = userMood.emoji;
        todayMood = userMood.mood;
        colors = MoodColorUtil.getMoodColor(todayEmoji.toString());
        _isMoodLoaded = true;
      });
    } else {
      setState(() {
        _isMoodLoaded = true;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    String? url = await _userProfileController.getCurrentUserProfileImageUrl();
    setState(() {
      _imageUrl = url;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    try {
      setState(() {
        _isUploading = true;
      });

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        setState(() {
          _imageFile = file;
        });

        await _userProfileController.uploadCurrentUserProfilePicture(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await _userProfileController.signOut(context);
  }

  // build method
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isMoodLoaded
                          ? _buildProfileCard()
                          : const ShimmerWidget.rectangular(
                            width: double.infinity,
                            height: 90,
                          ),
                      const SizedBox(height: 20),
                      const Text(
                        "Settings",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsItem(
                        context,
                        "Update username",
                        Icons.person_outline,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const UpdateUsernameScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsItem(
                        context,
                        "Change password",
                        Icons.lock_outline,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const UpdatePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () => _logout(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              SizedBox(width: 15),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 4),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[2], width: 1),
        gradient: LinearGradient(
          colors: [Colors.white, colors[0], colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors[2], width: 3),
                ),
                child: ClipOval(
                  child:
                      (_imageFile != null || _imageUrl != null)
                          ? Image(
                            image:
                                _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : NetworkImage(_imageUrl!) as ImageProvider,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                          : Container(
                            width: 100,
                            height: 100,
                            color: Colors.orange.shade50,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.orange.shade300,
                            ),
                          ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _isUploading ? null : _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors[2],
                      shape: BoxShape.circle,
                    ),
                    child:
                        _isUploading
                            ? const SizedBox(
                              width: 9,
                              height: 9,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 12,
                            ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String?>(
                future: _userProfileController.getCurrentUsername(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ShimmerWidget.rectangular(
                      width: 120,
                      height: 20,
                    );
                  }
                  return Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      snapshot.data ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    todayEmoji!,
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  const SizedBox(width: 3.0),
                  Text(
                    todayMood!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon, {
    required Function() onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey, size: 22),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}
