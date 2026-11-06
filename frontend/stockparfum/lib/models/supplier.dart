/// Modèle représentant un fournisseur.
class Supplier {
  final int id;
  final String nom;
  final String telephone;
  final String? adresse;

  Supplier({
    required this.id,
    required this.nom,
    required this.telephone,
    this.adresse,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      adresse: json['adresse'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'telephone': telephone,
        'adresse': adresse,
      };
}
