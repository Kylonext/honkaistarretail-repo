import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web; // <-- Import langsung package web
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../session.dart';
import '../theme.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    final GoogleSignIn signIn = GoogleSignIn.instance;
    unawaited(
      signIn.initialize().then((_) {
        signIn.authenticationEvents
            .listen(_handleAuthenticationEvent)
            .onError(_handleAuthenticationError);
        signIn.attemptLightweightAuthentication();
      }),
    );
  }

  Future<void> _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    setState(() {
      _currentUser = user;
    });

    if (user != null) {
      await loginWithGoogleReal(user);
    }
  }

  void _handleAuthenticationError(Object e) {
    if (!mounted) return;
    showError("Google Authentication stream error");
  }

  Future<void> loginWithGoogleReal(GoogleSignInAccount user) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Session.baseUrl}/api/oauth-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user.email,
          'username': user.displayName ?? 'Trailblazer',
          'provider': 'google'
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Session.token = data['token'];
        Session.username = data['username'];
        Session.role = data['role'] ?? 'user';
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        showError("Database rejected Google Sign-In verification.");
      }
    } catch (e) {
      if (!mounted) return;
      showError("Backend synchronization failed.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Session.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(), 
          'password': _passwordController.text
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Session.token = data['token'];
        Session.role = data['role'];
        Session.username = data['username'];
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        showError(jsonDecode(response.body)['message'] ?? "Authentication Denied");
      }
    } catch (e) {
      if (!mounted) return;
      showError("Connection Failed. Verify server status.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> loginWithOAuth(String provider) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Session.baseUrl}/api/oauth-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': '${provider.toLowerCase()}_trailblazer', 
          'provider': provider
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Session.token = data['token'];
        Session.username = data['username'];
        Session.role = 'user';
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (!mounted) return;
      showError("OAuth Portal Unreachable.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.auto_awesome, color: primaryColor, size: 60),
                    const SizedBox(height: 16),
                    Text("HONKAI STAR RETAIL", style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: "Username"),
                      style: TextStyle(color: textColor),
                      validator: (val) => (val == null || val.trim().isEmpty) ? "Field required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password"),
                      style: TextStyle(color: textColor),
                      validator: (val) => (val == null || val.length < 6) ? "Password requires min 6 characters" : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      onPressed: _isLoading ? null : login,
                      child: const Text("LOGIN"),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("OR", style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    kIsWeb
                        ? SizedBox(
                            height: 54,
                            child: web.renderButton(), // <-- Merender tombol bawaan Google SDK untuk Web
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              side: BorderSide(color: primaryColor.withAlpha(100)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(Icons.g_mobiledata, color: primaryColor, size: 30),
                            label: Text("Login with Google", style: TextStyle(color: textColor)),
                            onPressed: _isLoading ? null : () async {
                              try {
                                await GoogleSignIn.instance.authenticate(); // <-- Digunakan hanya untuk Mobile (Android/iOS)
                              } catch (e) {
                                showError(e.toString());
                              }
                            },
                          ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: BorderSide(color: primaryColor.withAlpha(100)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.close, color: primaryColor, size: 22),
                      label: Text("Login with X", style: TextStyle(color: textColor)),
                      onPressed: _isLoading ? null : () => loginWithOAuth("X"),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: BorderSide(color: primaryColor.withAlpha(100)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.facebook, color: primaryColor, size: 24),
                      label: Text("Login with Facebook", style: TextStyle(color: textColor)),
                      onPressed: _isLoading ? null : () => loginWithOAuth("Facebook"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}