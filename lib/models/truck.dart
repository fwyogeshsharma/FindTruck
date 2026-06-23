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
    required this.phone,
    required this.location,
    this.photoCount = 4,
    this.verifiedByMaalgaadi = true,
  });

  final String id;
  final String plate;
  final String wheels; // '6', '10', '12', '14', '16+'
  final String body; // Open / Container / Tipper / Trailer / Tanker
  final Availability availability;
  final String area;
  final String distanceKm;
  final String updated;
  final String driverName;
  final String driverInitials;
  final String phone;
  final LatLng location;
  final int photoCount;
  final bool verifiedByMaalgaadi;

  Truck copyWith({LatLng? location, String? updated, String? distanceKm, String? area}) => Truck(
        id: id,
        plate: plate,
        wheels: wheels,
        body: body,
        availability: availability,
        area: area ?? this.area,
        distanceKm: distanceKm ?? this.distanceKm,
        updated: updated ?? this.updated,
        driverName: driverName,
        driverInitials: driverInitials,
        phone: phone,
        location: location ?? this.location,
        photoCount: photoCount,
        verifiedByMaalgaadi: verifiedByMaalgaadi,
      );

  /// True when the API provided real GPS coordinates for this truck.
  bool get hasLiveLocation =>
      location.latitude != 0 || location.longitude != 0;

  /// Maps a row from the FreightDesk API (`GET /api/trucks`).
  factory Truck.fromJson(Map<String, dynamic> j) {
    String? str(String k) {
      final v = j[k];
      return (v is String && v.trim().isNotEmpty) ? v : null;
    }

    final name = str('reported_by') ?? str('company_name') ?? 'Owner-driver';
    final phone = str('phone_number') ??
        str('phone_reported') ??
        str('reporter_phone') ??
        '';
    final lat = (j['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (j['longitude'] as num?)?.toDouble() ?? 0;
    final review = '${j['review_status'] ?? ''}'.toUpperCase();
    final verification = '${j['verification_status'] ?? ''}'.toUpperCase();

    return Truck(
      id: '${j['id']}',
      plate: str('license_plate') ?? '—',
      wheels: j['num_wheels'] != null ? '${j['num_wheels']}' : '—',
      body: str('vehicle_type') ?? 'Truck',
      availability: _availability('${j['loaded_status'] ?? ''}'),
      area: str('city') ?? str('location') ?? str('source') ?? '—',
      distanceKm: '',
      updated: _relativeTime(str('detected_at') ?? str('created_at')),
      driverName: name,
      driverInitials: _initials(name),
      phone: phone,
      location: LatLng(lat, lng),
      photoCount: (j['frames'] is int && j['frames'] > 0) ? j['frames'] as int : 4,
      verifiedByMaalgaadi: review == 'PASSED' || verification == 'VERIFIED',
    );
  }

  static Availability _availability(String loadedStatus) {
    switch (loadedStatus.toUpperCase()) {
      case 'EMPTY':
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

/// A search built on the finder home screen.
class TruckQuery {
  const TruckQuery({
    this.fromArea = 'Pune, Hadapsar',
    this.toArea = 'Mumbai',
    this.wheels = '10',
    this.body = 'Open',
    this.emptyOnly = true,
    this.verifiedOnly = true,
    this.maxDistanceKm = 25,
    this.availability = 'Empty now',
  });

  final String fromArea;
  final String toArea;
  final String wheels;
  final String body;
  final bool emptyOnly;
  final bool verifiedOnly;
  final double maxDistanceKm;
  final String availability;

  TruckQuery copyWith({
    String? fromArea,
    String? toArea,
    String? wheels,
    String? body,
    bool? emptyOnly,
    bool? verifiedOnly,
    double? maxDistanceKm,
    String? availability,
  }) =>
      TruckQuery(
        fromArea: fromArea ?? this.fromArea,
        toArea: toArea ?? this.toArea,
        wheels: wheels ?? this.wheels,
        body: body ?? this.body,
        emptyOnly: emptyOnly ?? this.emptyOnly,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        availability: availability ?? this.availability,
      );
}

/// A saved recurring search / alert.
class SavedSearch {
  const SavedSearch(this.title, this.route, this.alertOn, this.newCount);
  final String title;
  final String route;
  final bool alertOn;
  final String newCount;
}
