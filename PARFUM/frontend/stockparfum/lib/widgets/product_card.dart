import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/product.dart';

/// Carte présentant un produit dans les listes (dashboard, produits,
/// sélection pour mouvement de stock).
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProductCard({super.key, required this.product, this.onTap, this.trailing});

  static final _currencyFormat = NumberFormat.decimalPattern('fr_FR');

  @override
  Widget build(BuildContext context) {
    final imageFullUrl = product.imageUrl != null
        ? '${AppConstants.baseUrl.replaceAll('/api', '')}${product.imageUrl}'
        : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: imageFullUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageFullUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholderIcon(),
                          placeholder: (_, __) => Container(color: AppColors.background),
                        )
                      : _placeholderIcon(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.categorie}${product.marque != null && product.marque!.isNotEmpty ? ' • ${product.marque}' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${_currencyFormat.format(product.prixVente)} Ar',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          FontAwesomeIcons.boxesStacked,
                          size: 12,
                          color: product.stockFaible ? AppColors.danger : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.quantiteStock}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: product.stockFaible ? FontWeight.bold : FontWeight.normal,
                            color: product.stockFaible ? AppColors.danger : AppColors.textSecondary,
                          ),
                        ),
                        if (product.stockFaible) ...[
                          const SizedBox(width: 6),
                          const _LowStockBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: AppColors.primary.withOpacity(0.08),
      alignment: Alignment.center,
      child: const FaIcon(FontAwesomeIcons.sprayCanSparkles, color: AppColors.primary, size: 20),
    );
  }
}

class _LowStockBadge extends StatelessWidget {
  const _LowStockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: const Text(
        'Stock faible',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.danger),
      ),
    );
  }
}
