import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/truck_repository.dart';
import '../models/message_template.dart';
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

  static const _kSavedSearches = 'saved_searches';
  static const _kMessageTemplates = 'message_templates';

  final List<SavedSearch> savedSearches = [];

  /// SMS templates the finder reuses when texting drivers.
  final List<MessageTemplate> messageTemplates = [];

  void updateQuery(TruckQuery q) {
    query = q;
    notifyListeners();
  }

  /// Restores saved searches from disk. Call once at startup.
  Future<void> loadSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSavedSearches);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => SavedSearch.fromJson(e.cast<String, dynamic>()));
      savedSearches
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // Corrupt or old-format entry — drop it rather than blocking startup.
      await prefs.remove(_kSavedSearches);
    }
  }

  Future<void> _persistSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kSavedSearches, jsonEncode(savedSearches.map((s) => s.toJson()).toList()));
  }

  // ── Message templates ──────────────────────────────────────────────────

  /// Restores SMS templates from disk, seeding the defaults on first run so
  /// the picker is never empty. Call once at startup.
  Future<void> loadMessageTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMessageTemplates);
    if (raw == null) {
      messageTemplates
        ..clear()
        ..addAll(MessageTemplate.defaults());
      notifyListeners();
      await _persistMessageTemplates();
      return;
    }
    try {
      final list = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => MessageTemplate.fromJson(e.cast<String, dynamic>()));
      messageTemplates
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // Corrupt entry — fall back to the seeded defaults rather than an empty
      // list, so the finder can still message drivers.
      messageTemplates
        ..clear()
        ..addAll(MessageTemplate.defaults());
      notifyListeners();
      await _persistMessageTemplates();
    }
  }

  Future<void> _persistMessageTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMessageTemplates,
        jsonEncode(messageTemplates.map((t) => t.toJson()).toList()));
  }

  /// Adds a new template (newest first) and returns it.
  Future<MessageTemplate> addTemplate(String title, String body) async {
    final t = MessageTemplate(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      body: body.trim(),
    );
    messageTemplates.insert(0, t);
    notifyListeners();
    await _persistMessageTemplates();
    return t;
  }

  /// Updates the title/body of an existing template.
  Future<void> updateTemplate(String id, String title, String body) async {
    final i = messageTemplates.indexWhere((t) => t.id == id);
    if (i < 0) return;
    messageTemplates[i] =
        messageTemplates[i].copyWith(title: title.trim(), body: body.trim());
    notifyListeners();
    await _persistMessageTemplates();
  }

  Future<void> removeTemplate(String id) async {
    messageTemplates.removeWhere((t) => t.id == id);
    notifyListeners();
    await _persistMessageTemplates();
  }

  /// Whether [q] is already saved — drives the "Saved" state on the button.
  bool isSearchSaved(TruckQuery q) => savedSearches.any((s) => s.query == q);

  /// Saves [q]. Returns false when an identical search was already saved.
  Future<bool> saveSearch(TruckQuery q) async {
    if (isSearchSaved(q)) return false;
    savedSearches.insert(
      0,
      SavedSearch(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        query: q,
      ),
    );
    notifyListeners();
    await _persistSavedSearches();
    return true;
  }

  Future<void> removeSavedSearch(String id) async {
    savedSearches.removeWhere((s) => s.id == id);
    notifyListeners();
    await _persistSavedSearches();
  }

  Future<void> setSearchAlert(String id, bool on) async {
    final i = savedSearches.indexWhere((s) => s.id == id);
    if (i < 0) return;
    savedSearches[i] = savedSearches[i].copyWith(alertOn: on);
    notifyListeners();
    await _persistSavedSearches();
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
