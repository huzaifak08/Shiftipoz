import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shiftipoz/components/custom_button.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/models/price_details.dart';
import 'package:shiftipoz/models/location_data.dart';
import 'package:shiftipoz/providers/my_product_provider/my_product_provider.dart';
import 'package:shiftipoz/providers/product_provider/product_provider.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/services/location_service.dart';

class AddUpdateProductView extends ConsumerStatefulWidget {
  final ProductModel? productModel;
  const AddUpdateProductView({super.key, this.productModel});

  @override
  ConsumerState<AddUpdateProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends ConsumerState<AddUpdateProductView> {
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _securityController;
  late final TextEditingController _authorController;

  // --- STATE VARIABLES ---
  final List<File> _newImages = [];
  List<String> _existingNetworkImages = [];
  TransactionType _selectedType = TransactionType.giveaway;
  String _selectedPeriod = 'day';
  CategoryType _selectedCategory = CategoryType.books;
  bool _isUpdate = false;

  @override
  void initState() {
    super.initState();
    _isUpdate = widget.productModel != null;

    _titleController = TextEditingController(text: widget.productModel?.title);
    _descController = TextEditingController(
      text: widget.productModel?.description,
    );
    _priceController = TextEditingController(
      text: _isUpdate ? widget.productModel?.priceDetails.value.toString() : "",
    );
    _securityController = TextEditingController(
      text: _isUpdate
          ? widget.productModel?.priceDetails.securityDeposit?.toString()
          : "",
    );
    _authorController = TextEditingController(
      text: _isUpdate ? widget.productModel?.metadata['author'] : "",
    );

    if (_isUpdate) {
      _selectedType = widget.productModel!.transactionType;
      _selectedCategory = widget.productModel!.categoryType;
      _selectedPeriod = widget.productModel!.priceDetails.period ?? 'day';
      _existingNetworkImages = List.from(widget.productModel!.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _securityController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final locData = await LocationService.getCurrentLocation();
    if (locData == null) return;

    final draftProduct = ProductModel(
      id: _isUpdate ? widget.productModel!.id : '',
      ownerId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      images: _existingNetworkImages,
      categoryType: _selectedCategory,
      transactionType: _selectedType,
      priceDetails: PriceDetails(
        value:
            (_selectedType == TransactionType.sell ||
                _selectedType == TransactionType.rent)
            ? (double.tryParse(_priceController.text) ?? 0.0)
            : 0.0,
        period: _selectedType == TransactionType.rent ? _selectedPeriod : null,
        securityDeposit: _selectedType == TransactionType.borrow
            ? (double.tryParse(_securityController.text) ?? 5.0)
            : null,
        isFree: _selectedType == TransactionType.giveaway,
      ),
      locationData: LocationData(
        latitude: locData['lat'],
        longitude: locData['lng'],
        geohash: locData['hash'],
        cityName: locData['city'],
        addressHidden: "Approximate Location",
      ),
      metadata: {'author': _authorController.text.trim(), 'condition': 'Good'},
      isAvailable: true,
      createdAt: _isUpdate ? widget.productModel!.createdAt : DateTime.now(),
      isSynced: true,
    );

    if (_isUpdate) {
      await ref
          .read(myProductsProvider.notifier)
          .editProduct(draftProduct, _newImages);
    } else {
      await ref
          .read(productProvider.notifier)
          .addProduct(draftProduct, _newImages);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdate ? "Edit Listing" : "List a New Item"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(theme),
              const SizedBox(height: 30),
              _buildSectionTitle("Product Details", theme),
              _buildTextField(_titleController, "Title", Icons.title, theme),
              _buildTextField(
                _descController,
                "Description",
                Icons.description,
                theme,
                maxLines: 3,
              ),

              if (_selectedCategory == CategoryType.books)
                _buildTextField(
                  _authorController,
                  "Author Name",
                  Icons.person,
                  theme,
                ),

              const SizedBox(height: 25),
              _buildSectionTitle("Transaction Type", theme),
              _buildTransactionSelector(theme),

              const SizedBox(height: 20),
              _buildPriceSection(theme),

              const SizedBox(height: 40),
              CustomButton(
                isLoading: productState.isLoading,
                theme: theme,
                title: _isUpdate ? "Update Product" : "Post Product",
                onPressed: _submit,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    if (_selectedType == TransactionType.giveaway) {
      return const SizedBox.shrink();
    }

    final bool isRent = _selectedType == TransactionType.rent;
    final bool isBorrow = _selectedType == TransactionType.borrow;
    final bool isSell = _selectedType == TransactionType.sell;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSell || isRent)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _priceController,
                  isRent ? "Rental Fee" : "Sale Price",
                  Icons.payments_outlined,
                  theme,
                  keyboardType: TextInputType.number,
                ),
              ),
              if (isRent) ...[
                const SizedBox(width: 15),
                _buildPeriodDropdown(theme),
              ],
            ],
          ),

        if (isBorrow) ...[
          _buildTextField(
            _securityController,
            "Security Deposit (Min. 5.0)",
            Icons.security_rounded,
            theme,
            keyboardType: TextInputType.number,
            validator: (v) {
              final val = double.tryParse(v ?? "");
              if (val == null || val < 5.0) {
                return "Min. 5.0 insurance required for borrow";
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              "Insurance: This deposit protects you if the item is damaged.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPeriodDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButton<String>(
        value: _selectedPeriod,
        underline: const SizedBox(),
        items: ['day', 'week', 'month']
            .map((p) => DropdownMenuItem(value: p, child: Text("per $p")))
            .toList(),
        onChanged: (val) => setState(() => _selectedPeriod = val!),
      ),
    );
  }

  Widget _buildTransactionSelector(ThemeData theme) {
    return Row(
      children: TransactionType.values.map((type) {
        bool isSelected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              child: Center(
                child: Text(
                  type.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontSize: 13,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    ThemeData theme, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator:
            validator ??
            (v) => (v == null || v.isEmpty) ? "Required field" : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ..._existingNetworkImages.map(
            (url) => _ImagePreviewTile(
              imagePath: url,
              isNetwork: true,
              onDelete: () =>
                  setState(() => _existingNetworkImages.remove(url)),
            ),
          ),
          ..._newImages.map(
            (file) => _ImagePreviewTile(
              imagePath: file.path,
              isNetwork: false,
              onDelete: () => setState(() => _newImages.remove(file)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  final String imagePath;
  final bool isNetwork;
  final VoidCallback onDelete;

  const _ImagePreviewTile({
    required this.imagePath,
    required this.isNetwork,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 110,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: isNetwork
                  ? NetworkImage(imagePath)
                  : FileImage(File(imagePath)) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 15,
          child: GestureDetector(
            onTap: onDelete,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
