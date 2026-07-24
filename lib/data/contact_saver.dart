import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/truck.dart';
import '../state/app_state.dart';

/// Saves the driver to the phone's address book as `Tr-Name-Location` (e.g.
/// `Tr-AmanYadav-Jaipur`) the first time the finder calls them.
///
/// Best-effort by design: numbers already saved are skipped so repeated calls
/// never pile up duplicates, and any failure (permission denied, unsupported
/// platform, plugin error) is swallowed so it can never block placing the
/// call. Runs silently — the only visible step is the one-time OS permission
/// prompt.
Future<void> saveDriverContact({
  required Truck truck,
  required String number,
  required AppState state,
}) async {
  if (kIsWeb) return; // No contacts API on web.
  final key = _numberKey(number);
  if (key.isEmpty || state.isContactSaved(key)) return;
  try {
    final status =
        await FlutterContacts.permissions.request(PermissionType.readWrite);
    final granted = status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
    if (!granted) return;
    final contact = Contact(
      name: Name(first: truck.contactName),
      phones: [Phone(number: number)],
    );
    await FlutterContacts.create(contact);
    await state.markContactSaved(key);
  } catch (_) {
    // Contacts are a convenience, not required to reach the driver — ignore.
  }
}

/// The last 10 digits of a number, so '+91 99887 76655' and '9988776655'
/// count as the same driver (matches TruckPhone.key).
String _numberKey(String number) {
  final d = number.replaceAll(RegExp(r'\D'), '');
  return d.length > 10 ? d.substring(d.length - 10) : d;
}
