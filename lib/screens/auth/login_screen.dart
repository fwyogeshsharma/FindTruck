import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';
import '../main_scaffold.dart';
import 'register_screen.dart';

/// Login (FreightDesk `POST /api/auth/login`). Phone + password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
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
      await context.read<AuthService>().login(
            phone: _phone.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = (e.status == 401 || e.status == 400)
          ? 'Wrong phone or password.'
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                children: [
                  const FinderLogo(size: 56),
                  const SizedBox(height: 22),
                  Text('Welcome back',
                      style: AppText.sans(
                          size: 24, weight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 3),
                  Text('फिर से स्वागत है',
                      style: AppText.deva(size: 15, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text('Log in to find empty trucks near you.',
                      style: AppText.sans(
                          size: 13.5, color: AppColors.muted, height: 1.5)),
                  const SizedBox(height: 26),
                  TextFieldBox(
                    label: 'Phone',
                    hi: 'फ़ोन नंबर',
                    placeholder: '98765 43210',
                    keyboardType: TextInputType.phone,
                    controller: _phone,
                  ),
                  PasswordField(
                      label: 'Password', hi: 'पासवर्ड', controller: _password),
                  if (_error != null) ErrorBanner(_error!),
                ],
              ),
            ),
            BottomBar(children: [
              PrimaryBtn(_submitting ? 'Logging in…' : 'Log in',
                  icon: 'arrow',
                  disabled: !_valid || _submitting,
                  onTap: _submit),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New here? ',
                      style: AppText.sans(size: 13.5, color: AppColors.muted)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Create an account',
                        style: AppText.sans(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: AppColors.accent)),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
