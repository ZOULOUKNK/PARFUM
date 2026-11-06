/// Modèle représentant une ligne de l'historique des sorties de stock.
class StockMovement {
  final int id;
  final String produitNom;
  final String categorie;
  final int quantite;
  final String date;
  final String heure;
  final String? motif;

  StockMovement({
    required this.id,
    required this.produitNom,
    required this.categorie,
    required this.quantite,
    required this.date,
    required this.heure,
    this.motif,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as int,
      produitNom: json['produit_nom'] as String,
      categorie: json['categorie'] as String,
      quantite: json['quantite'] as int,
      date: json['date'] as String,
      heure: json['heure'] as String,
      motif: json['motif'] as String?,
    );
  }
}
