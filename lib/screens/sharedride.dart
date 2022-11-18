import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:sharedride/api_keys.dart';
import 'package:sharedride/services/sharedride_service.dart';

import '../config.dart';
import 'map.dart';

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({Key? key}) : super(key: key);

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  final List<String> _steps = [];

  @override
  void initState() {
    super.initState();
    hasSharedRide().then((hasSharedRide) {
      if (hasSharedRide) {
        //TODO spinner
        _navigateToMapScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Créer ton shared ride, ou bien rejoins en un!',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              Expanded(
                  key: UniqueKey(),
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: _steps.length,
                    onReorder: _moveTile,
                    itemBuilder: _buildTile,
                  )),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _steps.length > 1 ? null : Colors.grey,
                  ),
                  onPressed: _onCreateSharedRidePressed,
                  child: const Text('Créer un shared ride')),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => _navigateToMapScreen(),
                  //TODO AlertDialog to get sharedRideId
                  child: const Text('Rejoindre un shared ride')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
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
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        trailing: IconButton(
            color: Colors.red,
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
    createSharedRide(_steps).then((isCreated) {
      if (isCreated) {
        _navigateToMapScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Erreur lors de la création du shared ride.")));
      }
    });
  }

  void _navigateToMapScreen() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MapScreen()));
  }
}
