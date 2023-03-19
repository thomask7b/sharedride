import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sharedride/models/user.dart';
import 'package:sharedride/screens/components/button.dart';
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
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text("Créer un compte"),
          backgroundColor: Colors.grey[900],
        ),
        body: Container(
          margin: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.account_circle, size: 100),
              const SizedBox(height: 40),
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
                        if (value!.isEmpty) {
                          return "Le mot de passe ne peut pas être vide";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        labelText: "Confirmez votre mot de passe",
                        fillColor: Colors.grey.shade200,
                        filled: true,
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return "Les mots de passes sont différents";
                        }
                        return null;
                      },
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Button(
                            onTap: _createAccount,
                            text: 'Créer un compte',
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  _createAccount() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Création du compte en cours...')),
      );
      createAccount(User(_usernameController.text, _passwordController.text))
          .then(_manageCreateAccountResponse);
    }
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
