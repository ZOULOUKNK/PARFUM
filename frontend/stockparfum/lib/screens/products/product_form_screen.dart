import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/supplier.dart';
import '../../providers/product_provider.dart';
import '../../services/category_service.dart';
import '../../services/supplier_service.dart';

/// Écran de création ou de modification d'un produit.
/// Si [product] est fourni, le formulaire est pré-rempli en mode édition.
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _marqueController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _seuilController = TextEditingController(text: '5');

  int? _categorieId;
  int? _fournisseurId;
  File? _pickedImage;
  bool _isSaving = false;

  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  bool _isLoadingLists = true;

  @override
  void initState() {
    super.initState();
    _loadLists();

    final product = widget.product;
    if (product != null) {
      _nomController.text = product.nom;
      _marqueController.text = product.marque ?? '';
      _prixAchatController.text = product.prixAchat.toString();
      _prixVenteController.text = product.prixVente.toString();
      _quantiteController.text = product.quantiteStock.toString();
      _seuilController.text = product.seuilMinimum.toString();
      _categorieId = product.categorieId;
      _fournisseurId = product.fournisseurId;
    }
  }

  Future<void> _loadLists() async {
    try {
      final categories = await CategoryService().getAll();
      final suppliers = await SupplierService().getAll();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _suppliers = suppliers;
        _isLoadingLists = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLists = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _marqueController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _quantiteController.dispose();
    _seuilController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<ProductProvider>();

    final success = widget.isEditing
        ? await provider.updateProduct(
            id: widget.product!.id,
            nom: _nomController.text.trim(),
            categorieId: _categorieId!,
            marque: _marqueController.text.trim(),
            prixAchat: double.tryParse(_prixAchatController.text) ?? 0,
            prixVente: double.tryParse(_prixVenteController.text) ?? 0,
            quantiteStock: int.tryParse(_quantiteController.text) ?? 0,
            seuilMinimum: int.tryParse(_seuilController.text) ?? 5,
            fournisseurId: _fournisseurId,
            imagePath: _pickedImage?.path,
          )
        : await provider.createProduct(
            nom: _nomController.text.trim(),
            categorieId: _categorieId!,
            marque: _marqueController.text.trim(),
            prixAchat: double.tryParse(_prixAchatController.text) ?? 0,
            prixVente: double.tryParse(_prixVenteController.text) ?? 0,
            quantiteStock: int.tryParse(_quantiteController.text) ?? 0,
            seuilMinimum: int.tryParse(_seuilController.text) ?? 5,
            fournisseurId: _fournisseurId,
            imagePath: _pickedImage?.path,
          );

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

  String? _existingImageUrl() {
    final url = widget.product?.imageUrl;
    if (url == null) return null;
    return '${AppConstants.serverUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Modifier le produit' : 'Nouveau produit')),
      body: _isLoadingLists
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          image: _pickedImage != null
                              ? DecorationImage(image: FileImage(_pickedImage!), fit: BoxFit.cover)
                              : (_existingImageUrl() != null
                                  ? DecorationImage(image: NetworkImage(_existingImageUrl()!), fit: BoxFit.cover)
                                  : null),
                        ),
                        child: (_pickedImage == null && _existingImageUrl() == null)
                            ? const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32)
                            : null,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _pickImage,
                      child: const Text('Choisir une image du produit'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(labelText: 'Nom du produit *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Le nom est requis.' : null,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<int>(
                    initialValue: _categorieId,
                    decoration: const InputDecoration(labelText: 'Catégorie *'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom)))
                        .toList(),
                    onChanged: (value) => setState(() => _categorieId = value),
                    validator: (v) => v == null ? 'La catégorie est requise.' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _marqueController,
                    decoration: const InputDecoration(labelText: 'Marque'),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prixAchatController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Prix d\'achat (Ar)'),
                          validator: (v) => (v != null && v.isNotEmpty && double.tryParse(v) == null)
                              ? 'Nombre invalide'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _prixVenteController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Prix de vente (Ar) *'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (double.tryParse(v) == null) return 'Nombre invalide';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantiteController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantité en stock'),
                          validator: (v) => (v != null && v.isNotEmpty && int.tryParse(v) == null)
                              ? 'Entier invalide'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _seuilController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
                          validator: (v) => (v != null && v.isNotEmpty && int.tryParse(v) == null)
                              ? 'Entier invalide'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<int>(
                    initialValue: _fournisseurId,
                    decoration: const InputDecoration(labelText: 'Fournisseur (optionnel)'),
                    items: _suppliers
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nom)))
                        .toList(),
                    onChanged: (value) => setState(() => _fournisseurId = value),
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
                        : Text(widget.isEditing ? 'Enregistrer les modifications' : 'Ajouter le produit'),
                  ),
                ],
              ),
            ),
    );
  }
}
