class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  UserModel({required this.id, required this.email, this.displayName, this.photoUrl});
}
