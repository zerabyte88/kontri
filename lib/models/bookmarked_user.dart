class BookmarkedUser {
  final String username;
  final String avatarUrl;
  final String? name;
  final String? bio;
  final String? location;

  const BookmarkedUser({
    required this.username,
    required this.avatarUrl,
    this.name,
    this.bio,
    this.location,
  });

  BookmarkedUser copyWith({
    String? username,
    String? avatarUrl,
    String? name,
    String? bio,
    String? location,
  }) {
    return BookmarkedUser(
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar_url': avatarUrl,
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
    };
  }

  factory BookmarkedUser.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    return BookmarkedUser(
      username: username,
      avatarUrl:
          json['avatar_url'] as String? ?? 'https://github.com/$username.png',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
    );
  }
}
