import 'package:latlong2/latlong.dart';

/// Truck availability — the colour-coded states from the design legend.
enum Availability {
  empty('Empty now', 'खाली अभी'),
  soon('Empty soon', 'जल्द खाली'),
  loaded('Loaded', 'लदा हुआ');

  const Availability(this.label, this.hi);
  final String label;
  final String hi;

  static Availability fromApi(String s) => switch (s) {
        'empty' => Availability.empty,
        'soon' => Availability.soon,
        _ => Availability.loaded,
      };
}

/// A callable number on a truck record. The API exposes up to three separate
/// phone fields and they don't all reach the same person — the reporter who
/// added the truck is not the driver — so each number carries who it reaches.
class TruckPhone {
  const TruckPhone(this.number, this.label);

  final String number;

  /// Who this number reaches ('Driver', 'Alternate', 'Reporter · …').
  final String label;

  /// Comparable form: the last 10 digits, so '+91 99887 76655' and
  /// '9988776655' are recognised as the same number and only listed once.
  String get key {
    final d = number.replaceAll(RegExp(r'\D'), '');
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }

  /// Display form: '+91 99887 76655' for 10-digit Indian numbers, else as-is.
  String get pretty {
    final d = number.replaceAll(RegExp(r'\D'), '');
    final local = d.length > 10 ? d.substring(d.length - 10) : d;
    if (local.length != 10) return number;
    return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
  }
}

/// A truck record sourced from the shared maalgaadi database. Every truck is
/// `verifiedByMaalgaadi` per the design's trust badge.
class Truck {
  const Truck({
    required this.id,
    required this.plate,
    required this.wheels,
    required this.body,
    required this.availability,
    required this.area,
    required this.distanceKm,
    required this.updated,
    required this.driverName,
    required this.driverInitials,
    required this.phones,
    required this.location,
    this.axle = '—',
    this.reportedBy = '',
    this.createdAt,
    this.photoCount = 4,
    this.verifiedByMaalgaadi = true,
  });

  final String id;
  final String plate;
  final String wheels; // '4', '6', '10', '12', '14', '16'
  final String body; // Open Body / Flat Bed / Container / …
  final String axle; // Single-Axle / Multi-Axle / '—'
  final Availability availability;
  final String area;
  final String distanceKm;
  final String updated;
  final String driverName; // the vehicle's driver (NOT the reporter)
  final String driverInitials;
  final String reportedBy; // the person who added/reported this truck

  /// Every distinct number on the record, best-first. May be empty.
  final List<TruckPhone> phones;

  final LatLng location;
  final DateTime? createdAt; // when the record was added, for "latest" sort
  final int photoCount;
  final bool verifiedByMaalgaadi;

  Truck copyWith({LatLng? location, String? updated, String? distanceKm, String? area}) => Truck(
        id: id,
        plate: plate,
        wheels: wheels,
        body: body,
        axle: axle,
        availability: availability,
        area: area ?? this.area,
        distanceKm: distanceKm ?? this.distanceKm,
        updated: updated ?? this.updated,
        driverName: driverName,
        driverInitials: driverInitials,
        reportedBy: reportedBy,
        phones: phones,
        location: location ?? this.location,
        createdAt: createdAt,
        photoCount: photoCount,
        verifiedByMaalgaadi: verifiedByMaalgaadi,
      );

  /// The number to dial when the finder doesn't pick one — the driver's if the
  /// record has it, otherwise the best available. Empty when there is none.
  String get phone => phones.isEmpty ? '' : phones.first.number;

  /// Whether the call sheet should ask which number to dial.
  bool get hasMultiplePhones => phones.length > 1;

  /// True when the API provided real GPS coordinates for this truck.
  bool get hasLiveLocation =>
      location.latitude != 0 || location.longitude != 0;

  /// Maps a row from the FreightDesk API (`GET /api/trucks`).
  factory Truck.fromJson(Map<String, dynamic> j) {
    String? str(String k) {
      final v = j[k];
      return (v is String && v.trim().isNotEmpty) ? v : null;
    }

    // The driver's name — falls back to a neutral label when the report did
    // not capture it. We deliberately do NOT fall back to `reported_by` here:
    // the person who added the truck is not the driver.
    final driver = str('driver_name') ?? 'Owner-driver';
    final reporter = str('reported_by') ?? str('company_name') ?? '';
    // All three phone fields are kept, not just the first non-empty one: a
    // record often carries both the driver's number and the reporter's, and
    // the finder should get to choose which to ring. Order is best-first and
    // duplicates (same number in two fields) are collapsed.
    final phones = <TruckPhone>[];
    void addPhone(String? raw, String label) {
      if (raw == null || raw.trim().isEmpty) return;
      final p = TruckPhone(raw.trim(), label);
      if (p.key.isEmpty || phones.any((e) => e.key == p.key)) return;
      phones.add(p);
    }

    addPhone(str('phone_number'), 'Driver');
    addPhone(str('phone_reported'), 'Alternate');
    addPhone(str('reporter_phone'),
        reporter.isEmpty ? 'Reporter' : 'Reporter · $reporter');
    final lat = (j['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (j['longitude'] as num?)?.toDouble() ?? 0;
    final review = '${j['review_status'] ?? ''}'.toUpperCase();
    final verification = '${j['verification_status'] ?? ''}'.toUpperCase();

    return Truck(
      id: '${j['id']}',
      plate: str('license_plate') ?? '—',
      wheels: j['num_wheels'] != null ? '${j['num_wheels']}' : '—',
      body: str('body_type') ?? str('vehicle_type') ?? 'Truck',
      axle: str('axle_type') ?? '—',
      availability: _availability('${j['loaded_status'] ?? ''}'),
      area: str('city') ?? str('location') ?? '—',
      distanceKm: '',
      updated: _relativeTime(str('detected_at') ?? str('created_at')),
      driverName: driver,
      driverInitials: _initials(driver),
      reportedBy: reporter,
      phones: phones,
      location: LatLng(lat, lng),
      createdAt: DateTime.tryParse(str('created_at') ?? str('detected_at') ?? ''),
      photoCount: (j['frames'] is int && j['frames'] > 0) ? j['frames'] as int : 4,
      verifiedByMaalgaadi: review == 'PASSED' || verification == 'VERIFIED',
    );
  }

  static Availability _availability(String loadedStatus) {
    switch (loadedStatus.toUpperCase()) {
      case 'EMPTY':
      case 'UNLOADED':
        return Availability.empty;
      case 'LOADED':
        return Availability.loaded;
      default:
        return Availability.soon;
    }
  }

  static String _relativeTime(String? iso) {
    if (iso == null) return 'recently';
    final t = DateTime.tryParse(iso);
    if (t == null) return 'recently';
    final diff = DateTime.now().toUtc().difference(t.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'))..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

/// A search built on the Find Vehicle screen. `'Any'` on a chip field (or an
/// empty [location]) means "don't filter on this".
class TruckQuery {
  const TruckQuery({
    this.location = '',
    this.wheels = 'Any',
    this.body = 'Any',
    this.axle = 'Any',
    this.emptyOnly = false,
    this.verifiedOnly = false,
    this.maxDistanceKm = 25,
    this.availability = 'All',
  });

  /// Location the finder wants a truck from (matched against the truck's
  /// city/location, and passed to the API as a free-text query).
  final String location;
  final String wheels;
  final String body;
  final String axle;
  final bool emptyOnly;
  final bool verifiedOnly;
  final double maxDistanceKm;
  final String availability;

  TruckQuery copyWith({
    String? location,
    String? wheels,
    String? body,
    String? axle,
    bool? emptyOnly,
    bool? verifiedOnly,
    double? maxDistanceKm,
    String? availability,
  }) =>
      TruckQuery(
        location: location ?? this.location,
        wheels: wheels ?? this.wheels,
        body: body ?? this.body,
        axle: axle ?? this.axle,
        emptyOnly: emptyOnly ?? this.emptyOnly,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        availability: availability ?? this.availability,
      );

  /// Number of active (non-"Any") structured filters — for the filter badge.
  int get activeCount => [
        location.trim().isNotEmpty,
        wheels != 'Any',
        body != 'Any',
        axle != 'Any',
        emptyOnly,
        verifiedOnly,
      ].where((v) => v).length;

  /// The non-location filters, as chip-style labels ('10-wheel', 'Open', …).
  List<String> get filterLabels => [
        if (wheels != 'Any') '$wheels-wheel',
        if (body != 'Any') body,
        if (axle != 'Any') axle,
        if (emptyOnly) availability == 'All' ? 'Empty now' : availability,
        if (verifiedOnly) 'Verified',
      ];

  Map<String, dynamic> toJson() => {
        'location': location,
        'wheels': wheels,
        'body': body,
        'axle': axle,
        'emptyOnly': emptyOnly,
        'verifiedOnly': verifiedOnly,
        'maxDistanceKm': maxDistanceKm,
        'availability': availability,
      };

  factory TruckQuery.fromJson(Map<String, dynamic> j) => TruckQuery(
        location: j['location'] as String? ?? '',
        wheels: j['wheels'] as String? ?? 'Any',
        body: j['body'] as String? ?? 'Any',
        axle: j['axle'] as String? ?? 'Any',
        emptyOnly: j['emptyOnly'] as bool? ?? false,
        verifiedOnly: j['verifiedOnly'] as bool? ?? false,
        maxDistanceKm: (j['maxDistanceKm'] as num?)?.toDouble() ?? 25,
        availability: j['availability'] as String? ?? 'All',
      );

  // Value equality so the same search can't be saved twice.
  @override
  bool operator ==(Object other) =>
      other is TruckQuery &&
      other.location.trim().toLowerCase() == location.trim().toLowerCase() &&
      other.wheels == wheels &&
      other.body == body &&
      other.axle == axle &&
      other.emptyOnly == emptyOnly &&
      other.verifiedOnly == verifiedOnly &&
      other.maxDistanceKm == maxDistanceKm &&
      other.availability == availability;

  @override
  int get hashCode => Object.hash(location.trim().toLowerCase(), wheels, body,
      axle, emptyOnly, verifiedOnly, maxDistanceKm, availability);
}

/// A search the finder kept so they can re-run it later.
///
/// The [query] is the record — the labels shown on the card are derived from
/// it rather than stored, so a card can never describe something different
/// from what running it actually searches for.
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.query,
    this.alertOn = true,
  });

  final String id;
  final TruckQuery query;

  /// Whether the finder asked to be alerted about new matches.
  final bool alertOn;

  /// The filter line: '10-wheel · Open' or 'Any truck' when unfiltered.
  String get title {
    final parts = query.filterLabels;
    return parts.isEmpty ? 'Any truck' : parts.join(' · ');
  }

  /// The location line.
  String get route {
    final loc = query.location.trim();
    return loc.isEmpty ? 'All locations' : loc;
  }

  SavedSearch copyWith({bool? alertOn}) =>
      SavedSearch(id: id, query: query, alertOn: alertOn ?? this.alertOn);

  Map<String, dynamic> toJson() =>
      {'id': id, 'alertOn': alertOn, 'query': query.toJson()};

  factory SavedSearch.fromJson(Map<String, dynamic> j) => SavedSearch(
        id: '${j['id']}',
        alertOn: j['alertOn'] as bool? ?? true,
        query: TruckQuery.fromJson(
            (j['query'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}
