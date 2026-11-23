import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 8.1 Controladores de los 3 campos
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // 8.2 Errores por campo (en el Registro SÍ se muestran, para ayudar al usuario)
  String? _emailError;
  String? _passError;
  String? _confirmError;

  bool _isObscure = true;
  bool _isLoading = false;

  // 8.3 Reglas de validación
  static const String _domain = '@tecdesoftware.edu.mx';

  bool _isInstitutionalEmail(String email) {
    final re = RegExp(r'^[^\s@]+@tecdesoftware\.edu\.mx$');
    return re.hasMatch(email.toLowerCase());
  }

  bool _hasMinLength(String p) => p.length >= 8;
  bool _hasUpper(String p) => RegExp(r'[A-Z]').hasMatch(p);
  bool _hasLower(String p) => RegExp(r'[a-z]').hasMatch(p);
  bool _hasNumber(String p) => RegExp(r'\d').hasMatch(p);
  bool _hasSymbol(String p) => RegExp(r'[^A-Za-z0-9]').hasMatch(p);

  bool _isValidPassword(String p) =>
      _hasMinLength(p) && _hasUpper(p) && _hasLower(p) && _hasNumber(p) && _hasSymbol(p);

  // 8.4 Mensajes amigables según el código de error de Firebase
  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudo crear la cuenta. Intenta de nuevo.';
    }
  }

  // 8.5 Acción del botón "Crear cuenta"
  Future<void> _onSignUp() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    // Recalcular los errores de cada campo
    setState(() {
      _emailError = _isInstitutionalEmail(email)
          ? null
          : 'Usa tu correo institucional ($_domain)';
      _passError = _isValidPassword(pass)
          ? null
          : 'La contraseña no cumple todas las reglas';
      _confirmError = (confirm == pass && confirm.isNotEmpty)
          ? null
          : 'Las contraseñas no coinciden';
    });

    FocusScope.of(context).unfocus();
    if (_emailError != null || _passError != null || _confirmError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 8.6 Registrar el usuario en Firebase Authentication
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      // Firebase inicia sesión automáticamente al registrar:
      // cerramos esa sesión para que el usuario entre desde el Login
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 8.7 Avisar y regresar al Login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ya puedes iniciar sesión.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_firebaseErrorMessage(e))),
      );
    }
  }

  // 8.8 Una regla de la contraseña con su palomita (se actualiza al escribir)
  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: ok ? Colors.green : Colors.black87)),
      ],
    );
  }

  InputDecoration _decoration(String hint, IconData icon, String? error, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pass = _passCtrl.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Regístrate con tu correo institucional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Correo
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration('usuario$_domain', Icons.email, _emailError),
            ),
            const SizedBox(height: 12),
            // Contraseña
            TextField(
              controller: _passCtrl,
              obscureText: _isObscure,
              // setState para que las reglas se actualicen al escribir
              onChanged: (_) => setState(() {}),
              decoration: _decoration(
                'Contraseña',
                Icons.lock,
                _passError,
                suffix: IconButton(
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                  icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Reglas de la contraseña
            _rule('Mínimo 8 caracteres', _hasMinLength(pass)),
            _rule('Una letra mayúscula', _hasUpper(pass)),
            _rule('Una letra minúscula', _hasLower(pass)),
            _rule('Un número', _hasNumber(pass)),
            _rule('Un símbolo (ej. ! @ # \$)', _hasSymbol(pass)),
            const SizedBox(height: 12),
            // Confirmar contraseña
            TextField(
              controller: _confirmCtrl,
              obscureText: _isObscure,
              decoration: _decoration('Confirmar contraseña', Icons.lock_outline, _confirmError),
            ),
            const SizedBox(height: 20),
            MaterialButton(
              minWidth: double.infinity,
              height: 50,
              color: Colors.blue,
              disabledColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onPressed: _isLoading ? null : _onSignUp,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Crear cuenta',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}
