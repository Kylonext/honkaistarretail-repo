import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'; 
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
      signIn.initialize(
        clientId: '1051554978105-ibm0j8t30fq96q2t4t7du91du6mqc20q.apps.googleusercontent.com',
      ).then((_) async {
        // HARD RESET CACHE: Memutus sesi Google sebelumnya agar 
        // cache bersih total dan tidak memicu "Sign in as..." saat page di-refresh.
        try {
          await signIn.disconnect();
        } catch (_) {
          // Disconnect melempar error jika tidak ada cache, kita abaikan saja
        }

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
    showError("Google Authentication error: $e");
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
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400), 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.auto_awesome, color: primaryColor, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        "HONKAI STAR RETAIL", 
                        style: Theme.of(context).textTheme.headlineMedium, 
                        textAlign: TextAlign.center
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: "Username",
                          border: OutlineInputBorder(),
                        ),
                        style: TextStyle(color: textColor),
                        validator: (val) => (val == null || val.trim().isEmpty) ? "Field required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                        style: TextStyle(color: textColor),
                        validator: (val) => (val == null || val.length < 6) ? "Password requires min 6 characters" : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : login,
                        child: const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      kIsWeb
                          ? SizedBox(
                              height: 54,
                              child: (GoogleSignInPlatform.instance as dynamic).renderButton(),
                            )
                          : OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                side: BorderSide(color: primaryColor.withAlpha(100)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: Icon(Icons.g_mobiledata, color: primaryColor, size: 30),
                              label: Text("Sign in with Google", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                              onPressed: _isLoading ? null : () async {
                                try {
                                  // Dikembalikan ke .authenticate() sesuai struktur package versi ini
                                  await GoogleSignIn.instance.authenticate();
                                } catch (e) {
                                  showError(e.toString());
                                }
                              },
                            ),
                    ],
                  ),
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