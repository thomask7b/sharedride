class User {
  final String name;
  final String password;

  const User(
    this.name,
    this.password,
  );

  User.fromMap(Map<String, dynamic> map)
      : name = map['name'],
        password = map['password'];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'password': password,
    };
  }
}
