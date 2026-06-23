/// A FreightDesk account (the `user` object returned by auth endpoints).
class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.displayName,
    this.email,
    this.role,
  });

  final int id;
  final String phone;
  final String? displayName;
  final String? email;
  final String? role;

  String get name => (displayName?.isNotEmpty ?? false) ? displayName! : phone;

  String get initials {
    final n = name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'))..removeWhere((p) => p.isEmpty);
    if (parts.length == 1) {
      return (parts.first.length >= 2 ? parts.first.substring(0, 2) : parts.first)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        phone: '${j['phone'] ?? ''}',
        displayName: j['display_name'] as String?,
        email: j['email'] as String?,
        role: j['role'] as String?,
      );
}
