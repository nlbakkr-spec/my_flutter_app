class User {
  final String id;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  final String? fullName;
  final String? profilePictureUrl;
  final String? description;

  User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.fullName,
    this.profilePictureUrl,
    this.description,
  });

  /// Конвертация в JSON для сохранения в Google Sheets
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
      'fullName': fullName ?? '',
      'profilePictureUrl': profilePictureUrl ?? '',
      'description': description ?? '',
    };
  }

  /// Создание User из JSON
  factory User.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt() {
      final raw = json['createdAt'];
      if (raw == null || raw == '') return DateTime.now();
      try {
        return DateTime.parse(raw.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return User(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      passwordHash: (json['passwordHash'] ?? json['password_hash'] ?? '').toString(),
      createdAt: parseCreatedAt(),
      fullName: (json['fullName'] ?? json['name'])?.toString().trim().isEmpty == true
          ? null
          : (json['fullName'] ?? json['name'])?.toString().trim(),
      profilePictureUrl: (json['profilePictureUrl'] ?? '')?.toString(),
      description: (json['description'] ?? '')?.toString().trim().isEmpty == true
          ? null
          : (json['description'] ?? '')?.toString().trim(),
    );
  }

  /// Copy with для обновления данных
  /// Передай явно null чтобы обнулить поле, или не передавай чтобы оставить прежнее
  User copyWith({
    String? id,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    String? fullName,
    String? profilePictureUrl,
    String? description,
    bool clearFullName = false,
    bool clearDescription = false,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      description: clearDescription ? null : (description ?? this.description),
    );
  }

  /// Отображаемое имя
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    return email;
  }

  @override
  String toString() => 'User(id: $id, email: $email, fullName: $fullName)';
}
