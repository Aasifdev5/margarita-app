import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/main.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '71875387439-ieqi697tn881mbcs1o2jmtb77499h93q.apps.googleusercontent.com', // Android client ID
    serverClientId:
        '71875387439-2jqa28abnf9hfeq68i57jg899l4o6u72.apps.googleusercontent.com', // Web client ID
    scopes: ['email', 'profile'],
  );
  final TextEditingController _googleWhatsappController =
      TextEditingController();

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _whatsappController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Todos los campos son obligatorios';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://remoto.digital/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
          'whatsapp_number': _whatsappController.text.trim(),
        }),
      );

      print('Register response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] ?? '');
        await prefs.setString('user_name', data['user']?['name'] ?? '');
        await prefs.setString(
          'whatsapp_number',
          data['user']?['whatsapp_number'] ?? '',
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FoodHomeScreen()),
          );
        }
      } else {
        final data = json.decode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Error al registrarse';
        });
      }
    } catch (e) {
      print('Register error: $e');
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign out to ensure a fresh login
      await _googleSignIn.signOut();
      print('Google Sign-In: Signed out previous session');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _errorMessage = 'Registro con Google cancelado';
          _isLoading = false;
        });
        print('Google Sign-In: User cancelled');
        return;
      }

      print('Google Sign-In: User: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        setState(() {
          _errorMessage = 'No se pudo obtener el token de Google';
          _isLoading = false;
        });
        print('Google Sign-In: ID token is null');
        return;
      }

      print('Google ID Token: $idToken');

      final response = await http.post(
        Uri.parse('https://remoto.digital/api/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );

      print('Google Sign-In API Response Status: ${response.statusCode}');
      print('Google Sign-In API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'];
        if (token == null) {
          throw Exception('Token no recibido en la respuesta');
        }
        await prefs.setString('auth_token', token);
        await prefs.setString('user_name', data['user']?['name'] ?? '');
        await prefs.setString(
          'whatsapp_number',
          data['user']?['whatsapp_number'] ?? '',
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FoodHomeScreen()),
          );
        }
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        setState(() {
          _errorMessage = data['message'] ?? 'Error al registrarse con Google';
        });
      }
    } catch (e, stackTrace) {
      print('Google Sign-In Error: $e');
      print('Stack Trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error al registrarse con Google: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _promptForWhatsappNumber() async {
    _googleWhatsappController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Número de WhatsApp'),
          content: TextField(
            controller: _googleWhatsappController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Ingresa tu número de WhatsApp (ej. +1234567890)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('WhatsApp prompt cancelled');
                Navigator.pop(context, null);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final input = _googleWhatsappController.text.trim();
                if (input.isNotEmpty &&
                    RegExp(r'^\+?\d{10,15}$').hasMatch(input)) {
                  print('WhatsApp number accepted: $input');
                  Navigator.pop(context, input);
                } else {
                  print('Invalid WhatsApp number: $input');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ingresa un número de WhatsApp válido (10-15 dígitos)',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _whatsappController.dispose();
    _googleWhatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 140, height: 140),
                const SizedBox(height: 10),
                const Text(
                  'Registrarse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _nameController,
                  icon: Icons.person,
                  hintText: 'Nombre *',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.email,
                  hintText: 'Correo electrónico *',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  hintText: 'Contraseña *',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  icon: Icons.lock,
                  hintText: 'Confirmar Contraseña *',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _whatsappController,
                  icon: Icons.phone,
                  hintText: 'Número de WhatsApp *',
                  keyboardType: TextInputType.phone,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _isLoading ? null : _signUpWithGoogle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        height: 24,
                        width: 24,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.error,
                              size: 24,
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Registrarse con Google',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes una cuenta? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Inicia Sesión',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
