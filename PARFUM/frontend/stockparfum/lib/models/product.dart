/// Modèle représentant un produit (parfum, Antares, déodorant, crème...).
class Product {
  final int id;
  final String nom;
  final int categorieId;
  final String categorie;
  final String? marque;
  final double prixAchat;
  final double prixVente;
  final int quantiteStock;
  final int seuilMinimum;
  final String? imageUrl;
  final int? fournisseurId;
  final String? fournisseurNom;
  final String dateAjout;

  Product({
    required this.id,
    required this.nom,
    required this.categorieId,
    required this.categorie,
    this.marque,
    required this.prixAchat,
    required this.prixVente,
    required this.quantiteStock,
    required this.seuilMinimum,
    this.imageUrl,
    this.fournisseurId,
    this.fournisseurNom,
    required this.dateAjout,
  });

  /// Vrai lorsque la quantité en stock est descendue au niveau du seuil
  /// minimum (ou en dessous) : sert à afficher une alerte visuelle.
  bool get stockFaible => quantiteStock <= seuilMinimum;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      nom: json['nom'] as String,
      categorieId: json['categorie_id'] as int,
      categorie: json['categorie'] as String,
      marque: json['marque'] as String?,
      prixAchat: double.tryParse(json['prix_achat'].toString()) ?? 0,
      prixVente: double.tryParse(json['prix_vente'].toString()) ?? 0,
      quantiteStock: json['quantite_stock'] as int,
      seuilMinimum: json['seuil_minimum'] as int,
      imageUrl: json['image_url'] as String?,
      fournisseurId: json['fournisseur_id'] as int?,
      fournisseurNom: json['fournisseur_nom'] as String?,
      dateAjout: json['date_ajout'] as String,
    );
  }
}
