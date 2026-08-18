/// User data model.
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id:        json['id'] as int,
    name:      json['name'] as String,
    email:     json['email'] as String,
    role:      json['role'] as String,
    isActive:  json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id':         id,
    'name':       name,
    'email':      email,
    'role':       role,
    'is_active':  isActive,
    'created_at': createdAt,
  };
}
