import 'package:google_directions_api/google_directions_api.dart';
import 'package:objectid/objectid.dart';

import 'location.dart';

class SharedRide {
  final ObjectId id;
  final Map<String, Location?> usersAndLocations;
  final DirectionsResult direction;

  const SharedRide(this.id, this.usersAndLocations, this.direction);

  SharedRide.fromJson(this.id, Map<String, dynamic> json)
      : usersAndLocations = (json['usersAndLocations'] as Map<String, dynamic>)
            .map((key, value) =>
                MapEntry(key, value == null ? null : Location.fromMap(value))),
        direction = DirectionsResult.fromMap(json['direction']);
}
