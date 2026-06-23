import 'package:flutter/foundation.dart';

import '../data/truck_repository.dart';
import '../models/truck.dart';

/// App-wide state: the active search, saved trucks & searches, and the
/// truck data source. Backed by [MockTruckRepository]; swap in
/// [RestTruckRepository] to point at the live maalgaadi API.
class AppState extends ChangeNotifier {
  AppState(this.repo);

  final TruckRepository repo;

  TruckQuery query = const TruckQuery();

  final Set<String> _savedTruckIds = {};
  Set<String> get savedTruckIds => _savedTruckIds;

  final List<SavedSearch> savedSearches = [
    const SavedSearch('10,12-wheel · Open', 'Pune → Mumbai', true, '12 new today'),
    const SavedSearch('14-wheel · Trailer', 'Pune → Nagpur', true, '4 new today'),
    const SavedSearch('Any · Container', 'Near me · 25 km', false, ''),
  ];

  void updateQuery(TruckQuery q) {
    query = q;
    notifyListeners();
  }

  bool isSaved(String id) => _savedTruckIds.contains(id);

  void toggleSaved(String id) {
    if (!_savedTruckIds.add(id)) _savedTruckIds.remove(id);
    notifyListeners();
  }

  Future<List<Truck>> savedTrucks() async {
    final results = <Truck>[];
    for (final id in _savedTruckIds) {
      final t = await repo.byId(id);
      if (t != null) results.add(t);
    }
    return results;
  }
}
