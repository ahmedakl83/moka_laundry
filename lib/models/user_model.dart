enum UserRole { admin, dataEntry }

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final UserRole role;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role.name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.dataEntry,
    );
  }
}
