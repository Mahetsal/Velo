class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String blockStatus;
  final bool acceptedTerms;
  final String acceptedTermsVersion;
  final String acceptedTermsAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.blockStatus,
    this.acceptedTerms = true,
    this.acceptedTermsVersion = "1.0",
    this.acceptedTermsAt = "",
  });

  // Factory method to create a UserModel from a Map (for Firebase Realtime Database)
  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      blockStatus: map['blockStatus'],
      acceptedTerms: map['acceptedTerms'] ?? true,
      acceptedTermsVersion: map['acceptedTermsVersion'] ?? '1.0',
      acceptedTermsAt: map['acceptedTermsAt'] ?? '',
    );
  }

  // Method to convert a UserModel to a Map (for Firebase Realtime Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'blockStatus': blockStatus,
      'acceptedTerms': acceptedTerms,
      'acceptedTermsVersion': acceptedTermsVersion,
      'acceptedTermsAt': acceptedTermsAt,
    };
  }
}
