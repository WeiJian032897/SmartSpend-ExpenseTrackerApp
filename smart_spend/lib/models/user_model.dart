class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final bool notificationsEnabled;
  final String language;
  final bool twoFactorEnabled;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.notificationsEnabled = true,
    this.language = 'English',
    this.twoFactorEnabled = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      language: map['language'] ?? 'English',
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }
}