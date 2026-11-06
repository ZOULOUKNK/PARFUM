/// Modèle représentant une catégorie de produit.
class Category {
  final int id;
  final String nom;

  Category({required this.id, required this.nom});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'] as int, nom: json['nom'] as String);
  }
}
