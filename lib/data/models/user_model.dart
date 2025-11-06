class UserModel {
  final String? uid;
  final String? username;
  final String? email;
  final String? role;
  final String? gender;
  final String? fcmToken;
  final List<String>? childrenIds;
  final String? fatherId;
  final String? motherId;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.role,
    this.gender,
    this.fcmToken,
    this.childrenIds,
    this.fatherId,
    this.motherId,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? '',
      gender: map['gender'] ?? '',
      fcmToken: map['fcmtoken'],
      childrenIds:
          map['childrenIds'] != null
              ? List<String>.from(map['childrenIds'])
              : null,
      fatherId: map['FatherId'],
      motherId: map['MotherId'],
    );
  }

  String? get parentId => null;

  Map<String, dynamic> toMap() {
    final map = {
      'uid': uid,
      'email': email,
      'username': username,
      'role': role,
      'gender': gender,
      'fcmtoken': fcmToken,
      'createdAt': createdAt?.toIso8601String(),
    };

    if (role == 'Parent') {
      map['childrenIds'] != null ? List<String>.from(['childrenIds']) : [];
    } else if (role == 'Child') {
      map['FatherId'] = fatherId;
      map['MotherId'] = motherId;
    }

    return map;
  }
}
