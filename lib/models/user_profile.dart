class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String photoUrl;
  final String role; // AJOUTÉ : rôle ("client", "delivery", "admin")

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.photoUrl,
    required this.role, // AJOUTÉ
  });

  // Convertir le document Firestore (Map) vers la classe UserProfile
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'client', // Par défaut 'client' si le champ manque
    );
  }

  // Convertir l'objet en Map pour l'enregistrer dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'role': role,
    };
  }
}