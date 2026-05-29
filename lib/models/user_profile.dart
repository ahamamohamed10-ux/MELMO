class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String photoUrl; // AJOUTE CETTE LIGNE

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.photoUrl, // AJOUTE CETTE LIGNE AUSSI
  });
}