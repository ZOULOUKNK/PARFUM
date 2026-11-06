import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';

/// Écran de création ou de modification d'un fournisseur.
class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;
  const SupplierFormScreen({super.key, this.supplier});

  bool get isEditing => supplier != null;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    if (supplier != null) {
      _nomController.text = supplier.nom;
      _telephoneController.text = supplier.telephone;
      _adresseController.text = supplier.adresse ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<SupplierProvider>();

    final newSupplier = Supplier(
      id: widget.supplier?.id ?? 0,
      nom: _nomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      adresse: _adresseController.text.trim(),
    );

    final success = widget.isEditing
        ? await provider.updateSupplier(widget.supplier!.id, newSupplier)
        : await provider.createSupplier(newSupplier);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Une erreur est survenue.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Modifier le fournisseur' : 'Nouveau fournisseur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom *', prefixIcon: Icon(Icons.storefront_outlined)),
              validator: (v) => (v == null || v.isEmpty) ? 'Le nom est requis.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone *', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v == null || v.isEmpty) ? 'Le téléphone est requis.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _adresseController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(widget.isEditing ? 'Enregistrer les modifications' : 'Ajouter le fournisseur'),
            ),
          ],
        ),
      ),
    );
  }
}
