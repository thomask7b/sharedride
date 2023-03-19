import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sharedride/models/user.dart';
import 'package:sharedride/screens/components/button.dart';
import 'package:sharedride/screens/progressible_state.dart';
import 'package:sharedride/screens/sharedride.dart';

import '../services/auth_service.dart';
import '../utils.dart';
import 'create_account.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({Key? key}) : super(key: key);

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends ProgressibleState<LoginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FocusManager.instance.primaryFocus?.unfocus();
    authenticateSavedUser().then((isConnected) {
      if (isConnected) {
        _navigateToSharedRideScreen();
      } else {
        hideProgress();
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
        backgroundColor: Colors.grey[300],
        body: SafeArea(
            child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.lock, size: 100),
                      const SizedBox(height: 40),
                      const Text("Identifiez vous"),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                border: const UnderlineInputBorder(),
                                labelText: "Entrez votre nom d'utilisateur",
                                fillColor: Colors.grey.shade200,
                                filled: true,
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
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: const UnderlineInputBorder(),
                                labelText: "Entrez votre mot de passe",
                                fillColor: Colors.grey.shade200,
                                filled: true,
                              ),
                              validator: (value) {
                                if (!isValidPassword(value)) {
                                  return "Le mot de passe ne peut pas être vide";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                            Align(
                              alignment: Alignment.centerRight,
                              child:
                                  Button(onTap: _signIn, text: 'Se connecter'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                      thickness: 0.5,
                                      color: Colors.grey[400],
                                    )),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        'Rejoignez nous!',
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                      thickness: 0.5,
                                      color: Colors.grey[400],
                                    )),
                                  ],
                                ),
                              ),
                              Button(
                                onTap: _navigateToCreateAccountScreen,
                                text: 'Créer un compte',
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
        )));
  }

  _manageAuthenticationResponse(bool isAuthenticated) {
    if (isAuthenticated) {
      if (kDebugMode) {
        print("Authentification réussie.");
      }
      _navigateToSharedRideScreen();
    } else {
      if (kDebugMode) {
        print("Echec lors de l'authentification.");
      }
      hideProgress();
    }
  }

  _signIn() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      showProgress();
      authenticate(User(_usernameController.text, _passwordController.text))
          .then(_manageAuthenticationResponse);
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
