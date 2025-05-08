class User {
  final String? id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final List<String>? favoriteExercises;
  final Map<String, dynamic>? preferences;

  User({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.favoriteExercises,
    this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      favoriteExercises: json['favoriteExercises'] != null
          ? List<String>.from(json['favoriteExercises'])
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'favoriteExercises': favoriteExercises,
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? favoriteExercises,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteExercises: favoriteExercises ?? this.favoriteExercises,
      preferences: preferences ?? this.preferences,
    );
  }
}
