import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shiftipoz/components/custom_button.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/models/price_details.dart';
import 'package:shiftipoz/models/location_data.dart';
import 'package:shiftipoz/providers/product_provider/product_provider.dart'; // Adjust path
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart'; // To get ownerId

class AddUpdateProductView extends ConsumerStatefulWidget {
  const AddUpdateProductView({super.key});

  @override
  ConsumerState<AddUpdateProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends ConsumerState<AddUpdateProductView> {
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _securityController = TextEditingController();
  final _authorController = TextEditingController(); // Metadata for Books

  // --- FOCUS NODES ---
  final _titleFocus = FocusNode();
  final _descFocus = FocusNode();
  final _priceFocus = FocusNode();

  // --- STATE VARIABLES ---
  final List<File> _selectedImages = [];
  TransactionType _selectedType = TransactionType.giveaway;
  String _selectedPeriod = 'day';
  final CategoryType _selectedCategory = CategoryType.books;

  // Dummy Location for now (Will be fetched via Geolocator in next step)
  final double _lat = 33.6844;
  final double _lng = 73.0479;
  final String _city = "Islamabad";

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _securityController.dispose();
    _authorController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one image")));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final draftProduct = ProductModel(
      id: '', // Service generates this
      ownerId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      images: [], // Service uploads and fills this
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
        geohash: '', // Service generates this
        cityName: _city,
        addressHidden: "Sector F-7, Islamabad",
      ),
      metadata: {'author': _authorController.text.trim(), 'condition': 'Good'},
      isAvailable: true,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await ref
        .read(productProvider.notifier)
        .addProduct(draftProduct, _selectedImages);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "List a New Item",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
              _buildSectionTitle("Basic Details", theme),
              _buildTextField(
                _titleController,
                _titleFocus,
                "Product Title (e.g. The Alchemist)",
                Icons.title,
                theme,
              ),
              _buildTextField(
                _descController,
                _descFocus,
                "Describe the condition...",
                Icons.description,
                theme,
                maxLines: 3,
              ),

              const SizedBox(height: 25),
              _buildSectionTitle("Category Metadata", theme),
              if (_selectedCategory == CategoryType.books)
                _buildTextField(
                  _authorController,
                  null,
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
                title: "Post Product",
                onPressed: () => _submit(),
              ),

              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          }
          return Stack(
            children: [
              Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(_selectedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 15,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImages.removeAt(index)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionSelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: TransactionType.values.map((type) {
        bool isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: Text(
              type.name.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
            _priceFocus,
            "Price",
            Icons.attach_money,
            theme,
            keyboardType: TextInputType.number,
          ),
        ),
        if (_selectedType == TransactionType.rent) ...[
          const SizedBox(width: 15),
          DropdownButton<String>(
            value: _selectedPeriod,
            items: ['day', 'week', 'month']
                .map((p) => DropdownMenuItem(value: p, child: Text("per $p")))
                .toList(),
            onChanged: (val) => setState(() => _selectedPeriod = val!),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    FocusNode? node,
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
        focusNode: node,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
