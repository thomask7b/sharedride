import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sharedride/config.dart';
import 'package:sharedride/models/user.dart';
import 'package:sharedride/services/users_service.dart';

import '../utils.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
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
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(appName),
        ),
        body: Container(
          margin: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text("Créez un compte :"),
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
                        if (!isValidUsername(value)) {
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
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: "Confirmez votre mot de passe",
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return "Les mots de passes sont différents";
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
                                      content: Text(
                                          'Création du compte en cours...')),
                                );
                                createAccount(User(_usernameController.text,
                                        _passwordController.text))
                                    .then(_manageCreateAccountResponse);
                              }
                            },
                            child: const Text('Créer un compte'),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  _manageCreateAccountResponse(bool isCreated) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (isCreated) {
      const successMessage = "Création du compte réussie.";
      if (kDebugMode) {
        print(successMessage);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(successMessage)),
      );
      _navigateToLoginFormScreen(
          User(_usernameController.text, _passwordController.text));
    } else {
      if (kDebugMode) {
        print("Echec lors de l'authentification.");
      }
      _usernameController.text = "";
      _passwordController.text = "";
    }
  }

  _navigateToLoginFormScreen(User user) {
    Navigator.pop(context);
  }
}
