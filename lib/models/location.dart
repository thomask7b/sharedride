class Location {
  final double latitude;
  final double longitude;

  const Location(
    this.latitude,
    this.longitude,
  );

  Location.fromMap(Map<String, dynamic> map)
      : latitude = map['latitude'],
        longitude = map['longitude'];
}
