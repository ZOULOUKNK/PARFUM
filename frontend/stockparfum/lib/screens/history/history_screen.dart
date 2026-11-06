import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_movement.dart';
import '../../services/stock_service.dart';
import '../../widgets/error_view.dart';

/// Page dédiée à l'historique complet des sorties de stock : nom du
/// produit, catégorie, quantité sortie, date et heure.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = StockService();
  List<StockMovement> _movements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final movements = await _service.getHistoriqueSorties();
      setState(() => _movements = movements);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de charger l\'historique.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTime(String time) {
    // "heure_mouvement" arrive au format HH:MM:SS depuis MySQL
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}h${parts[1]}';
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des sorties')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ErrorView(message: _errorMessage!, onRetry: _load)
              : _movements.isEmpty
                  ? const Center(
                      child: Text('Aucune sortie enregistrée.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _movements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final movement = _movements[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const FaIcon(FontAwesomeIcons.arrowUpFromBracket, color: AppColors.danger, size: 16),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          movement.produitNom,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          movement.categorie,
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '-${movement.quantite}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_formatDate(movement.date)} • ${_formatTime(movement.heure)}',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
