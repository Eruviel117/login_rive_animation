import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';
//5.1 Importar Firebase Auth y la pantalla de libros
import 'package:firebase_auth/firebase_auth.dart';
import 'books_screen.dart';
//8.9 Importar la pantalla de registro
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controla si la contraseña se ve o se oculta
  bool _isObscure = true;

  // Controlador de la máquina de estados de Rive
  StateMachineController? _controller;
  // Variables (inputs) de la animación
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.2 Timer para detener la animación de mirar a los lados después de 3 segundos
  Timer? _typingDebonce;

  //2.1 crear variable para FocusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  // 4.1 Controladores de texto para los campos de email y contraseña
  final emailCrtl = TextEditingController();
  final passCrtl = TextEditingController();

  //5.2 Variable para mostrar el CircularProgressIndicator mientras carga
  bool _isLoading = false;

  //7.1 OWASP: un único mensaje genérico para cualquier fallo del Login.
  //No se indica qué campo falló para no revelar si el correo existe.
  static const String _invalidCredentialsMsg =
      'Credenciales inválidas. Verifica tu correo y contraseña.';

  //7.2 Mostrar el mensaje global y la animación de fallo del osito
  void _showInvalidCredentials() {
    _trigFail?.fire();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_invalidCredentialsMsg)),
    );
  }

  //4.4 Accion del botón de login
  //5.3 Convertir _onLogin en asíncrono (Future<void> ... async)
  Future<void> _onLogin() async {

    //Recortar espacios en blanco accidenatales
    final email = emailCrtl.text.trim();
    final pass = passCrtl.text;

    //4.6 Cerrar el teclado y osos neutro

    FocusScope.of(context).unfocus();
    _typingDebonce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //7.3 Solo validar que los campos no estén vacíos (sin Regex ni errores por campo)
    if (email.isEmpty || pass.isEmpty) {
      _showInvalidCredentials();
      return;
    }

    //5.4 Activar el CircularProgressIndicator
    setState(() {
      _isLoading = true;
    });

    try {
      //5.5 Autenticar usuario en Firebase (esperamos un par de segundos para ver el loading)
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      //5.6 Apagar loading, disparar éxito del osito y esperar a que termine su animación
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      //5.7 Navegar al catálogo de libros de Spring Boot
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BooksScreen()),
      );
    } catch (e) {
      //5.8 Si Firebase rechaza el login, apagar loading y mostrar al osito triste
      //7.4 Mismo mensaje genérico, sin marcar error en ningún campo específico
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showInvalidCredentials();
    }
  }
  
  //2.2 Crear los oyentes (listeners)
  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
    });

    _passwordFocusNode.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Obtiene el tamaño de la pantalla
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: const ['Login Machine'],
                    //1.2 Vincular la animación
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      //1.3 Verificar que inició bien
                      if (_controller == null) return;
                      //Agregar el controlador al escenario
                      artboard.addController(_controller!);
                      //1.4 Vincular las variables
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                //Para separar elementos
                const SizedBox(height: 10),
                //Email
                TextField(
                  //4.8 Vincular el controlador de texto al TextField
                  controller: emailCrtl,
                  //2.3 Asignar el FocusNode al TextField
                  focusNode: _emailFocusNode,
                  //1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //No tapes los ojos al ver el email
                      // _isHandsUp!.change(false);
                    }
                    //Si isChecking es null
                    if (_isChecking == null) return;
                    //Activa el modo chismoso
                    _isChecking!.change(true);
                    //3.4 Implementar recorrido de miradas a los lados mientras se escribe
                    //Ajuste de limites del 0 a 100
                    //80 medida de calibración
                    final lookValue =
                        (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                    _numLook?.value = lookValue;

                    //3.5 Debounce: si vuelve a teclear, reinicia el contador
                    _typingDebonce?.cancel();
                    //Crear nuevo timer
                    _typingDebonce = Timer(const Duration(seconds: 3), () {
                      //Si se cierra la pantalla, termina la ejecución
                      if (!mounted) return;
                      //Mirada neutra
                      _isChecking?.change(false);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'E-mail',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //Contraseña
                TextField(
                  //4.8 Vincular el controlador de texto al TextField
                  controller: passCrtl,
                  //2.3 Asignar el FocusNode al TextField
                  focusNode: _passwordFocusNode,
                  //1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isChecking != null) {
                      //No actives el modo chismoso en contraseña
                      //_isChecking!.change(false);
                    }
                    //Si isHandsUp es null
                    if (_isHandsUp == null) return;
                    //Tapa los ojos
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot password?",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  color: Colors.blue,
                  //Mantener el color azul mientras el botón está deshabilitado (cargando)
                  disabledColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  //Deshabilitar el botón mientras carga para evitar doble clic
                  onPressed: _isLoading ? null : _onLogin,
                  //5.9 Mostrar CircularProgressIndicator si está cargando, o el texto Login
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        //8.10 Ir al Registro con push (para poder regresar con la flecha)
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Liberar los FocusNodes
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    // Cancelar el timer si sigue activo
    _typingDebonce?.cancel();
    super.dispose();
  }
}