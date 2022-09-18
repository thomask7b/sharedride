import 'package:flutter/material.dart';
import 'package:sharedride/services/authentication_service.dart';
import 'package:sharedride/screens/sharedride.dart';
import 'package:sharedride/models/user.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({Key? key}) : super(key: key);

  @override
  _LoginFormScreenState createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text("Bienvenu sur Shared Ride"),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: "Entrez votre nom d'utilisateur",
                  ),
                  validator: (value) {
                    if (!_isValidUsername(value)) {
                      return "Ce nom d'utilsiateur est invalide";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: "Entrez votre mot de passe",
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Le mot de passe ne peut pas être vide";
                    }
                    return null;
                  },
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Authentification en cours...')),
                            );
                            authenticate(User(_usernameController.text,
                                    _passwordController.text))
                                .then(_manageAuthenticationResponse);
                          }
                        },
                        child: const Text('Se connecter'),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidUsername(String? username) {
    return username != null && username.isNotEmpty && !username.contains(" ");
  }

  _manageAuthenticationResponse(bool isAuthenticated) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (isAuthenticated) {
      print("Authentification réussie.");
      _navigateToSharedRideScreen(
          User(_usernameController.text, _passwordController.text));
    } else {
      print("Echec lors de l'authentification.");
    }
  }

  _navigateToSharedRideScreen(User user) {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SharedRideScreen(user: user)));
  }
}
