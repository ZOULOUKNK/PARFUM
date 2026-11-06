/// Modèle représentant l'administrateur connecté.
class Admin {
  final int id;
  final String nom;
  final String email;

  Admin({required this.id, required this.nom, required this.email});

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as int,
      nom: json['nom'] as String,
      email: json['email'] as String,
    );
  }
}
