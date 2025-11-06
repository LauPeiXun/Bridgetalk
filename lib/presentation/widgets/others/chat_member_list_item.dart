import 'package:bridgetalk/presentation/utils/mood_color_utils.dart';
import 'package:bridgetalk/presentation/widgets/general_widgets/custom_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:bridgetalk/application/controller/user_profile/user_profile_controller.dart';

class ChatMemberListItem extends StatefulWidget {
  final String uid;
  final String username;
  final String mood;
  final String emoji;
  final String gender;
  final void Function()? onTap;

  const ChatMemberListItem({
    super.key,
    required this.uid,
    required this.username,
    required this.mood,
    required this.emoji,
    required this.gender,
    required this.onTap,
  });

  @override
  State<ChatMemberListItem> createState() => _ChatMemberListItemState();
}

class _ChatMemberListItemState extends State<ChatMemberListItem> {
  String? _imageUrl;
  File? _imageFile;
  String? genderIcon;
  final UserProfileController _userProfileController = UserProfileController();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();

    if (widget.gender == 'Male') {
      genderIcon = '♂️';
    } else if (widget.gender == 'Female') {
      genderIcon = '♀️';
    } else {
      genderIcon = '';
    }
  }

  Future<void> _loadProfileImage() async { 
    String? url = await _userProfileController.getProfileImageUrl(widget.uid);
    setState(() {
      _imageUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Update mood colors dynamically on every build
    List<Color> colors = MoodColorUtil.getMoodColor(widget.emoji);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 5, right: 10, top: 0, bottom: 0),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        height: 81,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors[1], width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, colors[0]],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,

              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                child:
                    _imageFile != null
                        ? Image(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        )
                        : _imageUrl != null
                        ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/profileImage.png',
                                width: 66,
                                height: 66,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const ShimmerWidget.rectangular(
                                width: 66,
                                height: 66,
                              ),
                            );
                          },
                        )
                        : _imageUrl == null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/profileImage.png',
                            width: 66,
                            height: 66,
                            fit: BoxFit.cover,
                          ),
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const ShimmerWidget.rectangular(
                            width: 66,
                            height: 66,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        genderIcon ?? '',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    "Status : ${widget.emoji} ${widget.mood}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
