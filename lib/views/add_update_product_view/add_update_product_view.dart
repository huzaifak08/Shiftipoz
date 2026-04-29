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
  final List<File> _newImages = []; // Images picked from gallery
  List<String> _existingNetworkImages = []; // Images already on Firebase

  TransactionType _selectedType = TransactionType.giveaway;
  String _selectedPeriod = 'day';
  CategoryType _selectedCategory = CategoryType.books;
  bool _isUpdate = false;

  // Dummy Location (Replace with Geolocator logic later)
  final double _lat = 33.6844;
  final double _lng = 73.0479;
  final String _city = "Islamabad";

  @override
  void initState() {
    super.initState();
    _isUpdate = widget.productModel != null;

    // Initialize controllers with existing data if updating
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

    if (_newImages.isEmpty && _existingNetworkImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one image")));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final draftProduct = ProductModel(
      id: _isUpdate ? widget.productModel!.id : '',
      ownerId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      images:
          _existingNetworkImages, // Pass existing ones, service will handle new ones
      categoryType: _selectedCategory,
      transactionType: _selectedType,
      priceDetails: PriceDetails(
        value: double.tryParse(_priceController.text) ?? 0.0,
        period: _selectedType == TransactionType.rent ? _selectedPeriod : null,
        securityDeposit: double.tryParse(_securityController.text),
        isFree: _selectedType == TransactionType.giveaway,
      ),
      locationData: LocationData(
        latitude: _lat,
        longitude: _lng,
        geohash: _isUpdate ? widget.productModel!.locationData.geohash : '',
        cityName: _city,
        addressHidden: "Wah Cantt, Pakistan",
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
        title: Text(
          _isUpdate ? "Edit Listing" : "List a New Item",
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
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
              _buildSectionTitle("Book Details", theme),
              _buildTextField(
                _titleController,
                "Product Title",
                Icons.title,
                theme,
              ),
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

              if (_selectedType != TransactionType.giveaway) ...[
                const SizedBox(height: 20),
                _buildPriceSection(theme),
              ],

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

  Widget _buildImageSection(ThemeData theme) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // ADD BUTTON
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
          // EXISTING NETWORK IMAGES
          ..._existingNetworkImages.map(
            (url) => _ImagePreviewTile(
              imagePath: url,
              isNetwork: true,
              onDelete: () =>
                  setState(() => _existingNetworkImages.remove(url)),
            ),
          ),
          // NEW FILE IMAGES
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
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            _priceController,
            "Price",
            Icons.payments_outlined,
            theme,
            keyboardType: TextInputType.number,
          ),
        ),
        if (_selectedType == TransactionType.rent) ...[
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
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
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    ThemeData theme, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
        validator: (v) => v!.isEmpty ? "Required field" : null,
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
