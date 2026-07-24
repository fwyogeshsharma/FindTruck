/// A reusable SMS message the finder composes once and reuses per driver.
///
/// The [body] may contain the `{name}` token (also `{driver}`), which
/// [render] replaces with the actual driver's name at send time — so one
/// template greets every driver by their own name.
class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;

  /// Short label shown in the picker ('Ask if free', 'Rate & route', …).
  final String title;

  /// The message text, with optional `{name}` / `{driver}` placeholders.
  final String body;

  /// Matches `{name}` and `{driver}` (any case, tolerant of inner spaces).
  static final RegExp _token =
      RegExp(r'\{\s*(name|driver)\s*\}', caseSensitive: false);

  /// Whether the body actually uses the driver-name placeholder.
  bool get hasNamePlaceholder => _token.hasMatch(body);

  /// The message with the placeholder filled in. A blank [driverName] (or the
  /// neutral 'Owner-driver' fallback) collapses `{name} ` politely to nothing
  /// rather than printing an awkward empty greeting.
  String render({required String driverName}) {
    final name = driverName.trim();
    final usable = name.isNotEmpty && name.toLowerCase() != 'owner-driver';
    if (usable) return body.replaceAll(_token, name);
    // Drop the token and any single trailing space so "Namaste {name}, " reads
    // as "Namaste, " rather than "Namaste , ".
    return body.replaceAll(RegExp(r'\{\s*(name|driver)\s*\}\s?'), '');
  }

  MessageTemplate copyWith({String? title, String? body}) => MessageTemplate(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};

  factory MessageTemplate.fromJson(Map<String, dynamic> j) => MessageTemplate(
        id: '${j['id']}',
        title: (j['title'] as String?)?.trim().isNotEmpty == true
            ? j['title'] as String
            : 'Template',
        body: j['body'] as String? ?? '',
      );

  /// Templates seeded on first run so the feature is usable immediately.
  /// Drivers are greeted by name where it helps.
  static List<MessageTemplate> defaults() => const [
        MessageTemplate(
          id: 'seed-free',
          title: 'Truck free today?',
          body: 'Namaste {name}, I found your truck on truckfinder. '
              'Is it free for a load today? Please reply here to confirm.',
        ),
        MessageTemplate(
          id: 'seed-details',
          title: 'Share load details',
          body: 'Hi {name}, I have a load ready. Please share your current '
              'location and rate so we can confirm.',
        ),
        MessageTemplate(
          id: 'seed-callback',
          title: 'Please call back',
          body: 'Namaste {name}, I tried calling about your truck on '
              'truckfinder. Please call me back when free.',
        ),
      ];
}
