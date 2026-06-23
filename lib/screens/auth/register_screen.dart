import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/kit.dart';
import '../main_scaffold.dart';

/// Register (FreightDesk `POST /api/auth/register`).
/// Phone + password required; name & email optional, so drivers know who's
/// calling (mirrors the design's broker setup).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _valid =>
      _phone.text.trim().length >= 6 && _password.text.length >= 4;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().register(
            phone: _phone.text.trim(),
            password: _password.text,
            displayName: _name.text.trim(),
            email: _email.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.status == 409
          ? 'An account with this phone already exists.'
          : e.message);
    } catch (_) {
      setState(() => _error =
          'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowHeader(lead: 'back', onLead: () => Navigator.maybePop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                children: [
                  Text('Create your account',
                      style: AppText.sans(
                          size: 24, weight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 3),
                  Text('नया खाता बनाएँ',
                      style: AppText.deva(size: 15, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text("So drivers know who's calling about their truck.",
                      style: AppText.sans(
                          size: 13.5, color: AppColors.muted, height: 1.5)),
                  const SizedBox(height: 22),
                  TextFieldBox(
                      label: 'Phone',
                      hi: 'फ़ोन नंबर',
                      placeholder: '98765 43210',
                      keyboardType: TextInputType.phone,
                      controller: _phone),
                  PasswordField(
                      label: 'Password',
                      hi: 'पासवर्ड · कम से कम ४ अक्षर',
                      controller: _password),
                  TextFieldBox(
                      label: 'Name',
                      hi: 'आपका नाम · ज़रूरी नहीं',
                      placeholder: 'e.g. Imran S.',
                      controller: _name),
                  TextFieldBox(
                      label: 'Email',
                      hi: 'ईमेल · ज़रूरी नहीं',
                      placeholder: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      hint: 'Optional — for receipts & support',
                      controller: _email),
                  if (_error != null) ErrorBanner(_error!),
                ],
              ),
            ),
            BottomBar(children: [
              PrimaryBtn(_submitting ? 'Creating…' : 'Create account',
                  icon: 'arrow',
                  disabled: !_valid || _submitting,
                  onTap: _submit),
            ]),
          ],
        ),
      ),
    );
  }
}
