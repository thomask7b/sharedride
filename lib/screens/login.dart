import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sharedride/models/user.dart';
import 'package:sharedride/screens/sharedride.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../utils.dart';
import 'create_account.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({Key? key}) : super(key: key);

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    authenticateSavedUser().then((isConnected) {
      if (isConnected) {
        //TODO spinner
        _navigateToSharedRideScreen();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(appName),
      ),
      body: Container(
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
                      final trimmedValue = value!.trim();
                      _usernameController.text = trimmedValue;
                      if (!isValidUsername(trimmedValue)) {
                        return "Ce nom d'utilisateur est invalide";
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
                      if (!isValidPassword(value)) {
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
                              //TODO spinner
                            }
                          },
                          child: const Text('Se connecter'),
                        ),
                      )),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            _navigateToCreateAccountScreen();
                          },
                          child: const Text('Créer un compte'),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _manageAuthenticationResponse(bool isAuthenticated) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (isAuthenticated) {
      if (kDebugMode) {
        print("Authentification réussie.");
      }
      _navigateToSharedRideScreen();
    } else {
      const failedAuthMessage = "Echec lors de l'authentification.";
      if (kDebugMode) {
        print(failedAuthMessage);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(failedAuthMessage)),
      );
    }
  }

  _navigateToSharedRideScreen() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SharedRideScreen()));
  }

  _navigateToCreateAccountScreen() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CreateAccountScreen()));
  }
}
