import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:objectid/objectid.dart';
import 'package:sharedride/api_keys.dart';
import 'package:sharedride/screens/progressible_state.dart';
import 'package:sharedride/services/sharedride_service.dart';

import '../config.dart';
import '../services/auth_service.dart';
import 'components/menu_item.dart';
import 'login.dart';
import 'map.dart';

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({Key? key}) : super(key: key);

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends ProgressibleState<SharedRideScreen> {
  final List<String> _steps = [];
  final TextEditingController _dialogController = TextEditingController();

  @override
  void initState() {
    super.initState();
    hasSharedRide().then((hasSharedRide) {
      if (hasSharedRide) {
        _navigateToMapScreen();
      } else {
        hideProgress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(appName),
        backgroundColor: Colors.grey[900],
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              const PopupMenuItem<int>(
                value: 0,
                child:
                    MenuItem(icon: Icons.login_outlined, text: "Déconnexion"),
              ),
            ];
          }, onSelected: (value) {
            switch (value) {
              case 0:
                logout().then((value) => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const LoginFormScreen())));
                break;
            }
          }),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Container(
                margin: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.map_sharp, size: 100),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size.fromHeight(50),
                            backgroundColor: Colors.black87),
                        onPressed: () => showDialog(
                            context: context,
                            builder: (context) {
                              return _buildDialog();
                            }),
                        child: Row(
                          children: const [
                            Icon(Icons.group_add),
                            SizedBox(width: 20),
                            Text('Rejoindre un shared ride')
                          ],
                        )),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                              child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          )),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Etapes :',
                              style: TextStyle(color: Colors.grey[700]),
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
                    Expanded(
                        key: UniqueKey(),
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: _steps.length,
                          onReorder: _moveTile,
                          itemBuilder: _buildTile,
                        )),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(right: 70),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  fixedSize: const Size.fromHeight(50),
                                  backgroundColor: _steps.length > 1
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                                onPressed: _onCreateSharedRidePressed,
                                child: Row(children: const [
                                  Icon(Icons.add_road),
                                  SizedBox(width: 20),
                                  Text('Créer le shared ride')
                                ]))),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blueGrey.shade900,
          onPressed: () => _showInputAutoComplete(),
          child: const Icon(Icons.add)),
    );
  }

  void _onCreateSharedRidePressed() =>
      _steps.length > 1 ? _createSharedRideThenNavigateTo() : null;

  ListTile _buildTile(BuildContext context, int index) {
    return ListTile(
        key: UniqueKey(),
        title: Text(_steps[index]),
        tileColor: Colors.grey.shade200,
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        trailing: IconButton(
            color: Colors.blueGrey,
            onPressed: () => setState(() {
                  _steps.removeAt(index);
                }),
            icon: const Icon(Icons.delete)));
  }

  void _moveTile(int oldIndex, int newIndex) {
    setState(() {
      final int index = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final String tile = _steps.removeAt(oldIndex);
      _steps.insert(index, tile);
    });
  }

  Widget _buildDialog() {
    return AlertDialog(
      title: const Text('Rejoindre un shared ride.'),
      content: TextField(
        controller: _dialogController,
        decoration:
            const InputDecoration(hintText: "Entrez un ID de shared ride :"),
      ),
      actions: <Widget>[
        MaterialButton(
          color: Colors.blueGrey,
          textColor: Colors.white,
          child: const Text('Annuler'),
          onPressed: () {
            setState(() {
              Navigator.pop(context);
            });
          },
        ),
        MaterialButton(
          color: Colors.black87,
          textColor: Colors.white,
          child: const Text('OK'),
          onPressed: () {
            _getSharedRideThenNavigateTo(
                ObjectId.fromHexString(_dialogController.text));
          },
        ),
      ],
    );
  }

  Future<void> _showInputAutoComplete() async {
    Prediction? p = await PlacesAutocomplete.show(
      offset: 0,
      radius: 1000,
      types: [],
      strictbounds: false,
      context: context,
      apiKey: mapsApiKey,
      mode: Mode.overlay,
      language: "fr",
      decoration: InputDecoration(
        hintText: 'Prochaine étape',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
      ),
      components: [
        Component(Component.country, "fr")
      ], //TODO prendre en compte tout les pays
    );
    if (p?.description != null) {
      setState(() {
        _steps.add(p!.description!);
      });
    }
  }

  void _createSharedRideThenNavigateTo() {
    showProgress();
    createSharedRide(_steps).then((isCreated) {
      if (isCreated) {
        _navigateToMapScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Erreur lors de la création du shared ride.")));
      }
      hideProgress();
    });
  }

  void _getSharedRideThenNavigateTo(ObjectId sharedRideId) {
    showProgress();
    getSharedRide(sharedRideId).then((sharedRide) {
      if (sharedRide != null) {
        _navigateToMapScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Erreur lors de la récupération du shared ride.")));
      }
      hideProgress();
    });
  }

  void _navigateToMapScreen() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MapScreen()),
        (Route<dynamic> route) => false);
  }
}
