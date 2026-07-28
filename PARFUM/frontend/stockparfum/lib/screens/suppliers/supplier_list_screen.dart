import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/error_view.dart';
import 'supplier_form_screen.dart';

/// Écran listant les fournisseurs avec recherche et actions CRUD.
class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SupplierProvider>().loadSuppliers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le fournisseur'),
        content: Text('Voulez-vous vraiment supprimer "${supplier.nom}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<SupplierProvider>().deleteSupplier(supplier.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fournisseur supprimé.'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const SupplierFormScreen()),
          );
          if (created == true && mounted) context.read<SupplierProvider>().loadSuppliers();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un fournisseur…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => context.read<SupplierProvider>().search(value),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? ErrorView(message: provider.errorMessage!, onRetry: provider.loadSuppliers)
                    : provider.suppliers.isEmpty
                        ? const Center(
                            child: Text('Aucun fournisseur trouvé.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadSuppliers,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: provider.suppliers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final supplier = provider.suppliers[index];
                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const FaIcon(FontAwesomeIcons.truck, color: AppColors.primary, size: 16),
                                    ),
                                    title: Text(supplier.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '${supplier.telephone}${supplier.adresse != null && supplier.adresse!.isNotEmpty ? '\n${supplier.adresse}' : ''}',
                                    ),
                                    isThreeLine: supplier.adresse != null && supplier.adresse!.isNotEmpty,
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          final updated = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: supplier)),
                                          );
                                          if (updated == true && mounted) {
                                            context.read<SupplierProvider>().loadSuppliers();
                                          }
                                        } else if (value == 'delete') {
                                          _confirmDelete(supplier);
                                        }
                                      },
                                      itemBuilder: (ctx) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                        PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
