bool isValidUsername(String? username) {
  return username != null && username.isNotEmpty && !username.contains(" ");
}

bool isValidPassword(String? password) {
  return password!.isNotEmpty;
}
