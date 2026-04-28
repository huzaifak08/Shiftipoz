import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shake_detector/shake_detector.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  // Logic & State
  String _fromUnit = "Meters";
  String _toUnit = "Feet";
  String _selectedCategory = "Length";
  bool _isSwapped = false;

  // Controllers & Focus
  late ShakeDetector _detector;
  late ScrollController _categoryScrollController;
  late TextEditingController _fromController;
  late TextEditingController _toController;
  late FocusNode _fromFocusNode;
  late FocusNode _toFocusNode;

  // Data
  final Map<String, Map<String, double>> _unitData = {
    'Length': {
      'Meters': 1.0,
      'Feet': 3.28084,
      'Inches': 39.3701,
      'Kilometers': 0.001,
      'Miles': 0.000621371,
    },
    'Weight': {'Kg': 1.0, 'Pounds': 2.20462, 'Grams': 1000.0, 'Ounces': 35.274},
    'Volume': {
      'Liters': 1.0,
      'Gallons': 0.264172,
      'Milliliters': 1000.0,
      'Cups': 4.22675,
    },
    'Temp': {'Celsius': 1.0, 'Fahrenheit': 1.0, 'Kelvin': 1.0},
  };

  final List<String> _categories = ['Length', 'Weight', 'Volume', 'Temp'];
  final List<double> _chipWidths = [110, 110, 110, 100];

  @override
  void initState() {
    super.initState();
    _categoryScrollController = ScrollController();

    // Initialize Controllers with default values
    _fromController = TextEditingController(text: "1");
    _toController = TextEditingController(text: "3.28");

    _fromFocusNode = FocusNode();
    _toFocusNode = FocusNode();

    // Listeners for Bi-Directional Input
    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);

    // Shake to clear
    _detector = ShakeDetector.autoStart(
      onShake: () {
        _fromController.text = "0";
        HapticFeedback.mediumImpact();
      },
    );
  }

  @override
  void dispose() {
    _detector.stopListening();
    _categoryScrollController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  // ---------------- BI-DIRECTIONAL LOGIC ----------------

  void _onFromChanged() {
    if (!_fromFocusNode.hasFocus)
      return; // Only process if the user is typing here
    _performCalculation(isForward: true);
  }

  void _onToChanged() {
    if (!_toFocusNode.hasFocus)
      return; // Only process if the user is typing here
    _performCalculation(isForward: false);
  }

  void _performCalculation({required bool isForward}) {
    final String sourceText = isForward
        ? _fromController.text
        : _toController.text;
    final double inputVal = double.tryParse(sourceText) ?? 0;

    final String from = isForward ? _fromUnit : _toUnit;
    final String to = isForward ? _toUnit : _fromUnit;

    double result;
    if (_selectedCategory == 'Temp') {
      result = _convertTemperature(inputVal, from, to);
    } else {
      final baseValue = inputVal / _unitData[_selectedCategory]![from]!;
      result = baseValue * _unitData[_selectedCategory]![to]!;
    }

    // Update the other controller WITHOUT triggering its listener infinitely
    final targetController = isForward ? _toController : _fromController;
    final formattedResult = result.toStringAsFixed(
      result.truncateToDouble() == result ? 0 : 2,
    );

    if (targetController.text != formattedResult) {
      targetController.text = formattedResult;
    }
  }

  double _convertTemperature(double val, String from, String to) {
    if (from == to) return val;
    double celsius = from == 'Fahrenheit'
        ? (val - 32) * 5 / 9
        : from == 'Kelvin'
        ? val - 273.15
        : val;
    if (to == 'Fahrenheit') return (celsius * 9 / 5) + 32;
    if (to == 'Kelvin') return celsius + 273.15;
    return celsius;
  }

  void _handleSwap() {
    setState(() {
      _isSwapped = !_isSwapped;
      final tempUnit = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = tempUnit;

      // Keep the current "From" value and recalculate "To"
      _performCalculation(isForward: true);
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _fromUnit = _unitData[_selectedCategory]!.keys.first;
      _toUnit = _unitData[_selectedCategory]!.keys.elementAt(1);
      _performCalculation(isForward: true);
    });
    _animateCategoryToSelection();
  }

  void _animateCategoryToSelection() {
    if (!_categoryScrollController.hasClients) return;
    final index = _categories.indexOf(_selectedCategory);
    double targetOffset = index <= 1
        ? 0
        : _chipWidths.take(index).fold<double>(0, (a, b) => a + b) - 80;
    _categoryScrollController.animateTo(
      targetOffset.clamp(0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showUnitPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2541),
      builder: (context) {
        final units = _unitData[_selectedCategory]!.keys.toList();
        return ListView.builder(
          shrinkWrap: true,
          itemCount: units.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(
              units[index],
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              setState(() {
                if (isFrom)
                  _fromUnit = units[index];
                else
                  _toUnit = units[index];
                _performCalculation(isForward: true);
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  // ---------------- UI COMPONENTS ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildCategorySelector(),
              const SizedBox(height: 20),
              SizedBox(
                height: 330,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      top: _isSwapped ? 170 : 0,
                      left: 24,
                      right: 24,
                      child: _buildUnitCard(
                        "From",
                        _fromUnit,
                        _fromController,
                        _fromFocusNode,
                        true,
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      top: _isSwapped ? 0 : 170,
                      left: 24,
                      right: 24,
                      child: _buildUnitCard(
                        "To",
                        _toUnit,
                        _toController,
                        _toFocusNode,
                        false,
                      ),
                    ),
                    Center(child: _buildSwapButton()),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "Shake to clear value",
                  style: TextStyle(color: Colors.white10, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard(
    String label,
    String unit,
    TextEditingController controller,
    FocusNode focusNode,
    bool isOriginalTop,
  ) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) {
        final bool isActive = focusNode.hasFocus;
        return GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isActive ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFC0C0C0).withOpacity(0.5)
                    : Colors.white.withOpacity(0.05),
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showUnitPicker(isOriginalTop),
                      child: Row(
                        children: [
                          Text(
                            unit,
                            style: const TextStyle(
                              color: Color(0xFFC0C0C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFFC0C0C0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  cursorColor: const Color(0xFFC0C0C0),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isActive ? 32 : 28,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w300,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Text(
            'SHIFTIPOZ',
            style: TextStyle(
              color: Color(0xFFC0C0C0),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = _selectedCategory == category;
          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFC0C0C0).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isActive ? const Color(0xFFC0C0C0) : Colors.white10,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwapButton() {
    return GestureDetector(
      onTap: _handleSwap,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 500),
        turns: _isSwapped ? 0.5 : 0,
        child: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFC0C0C0),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0B132B), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.swap_vert_rounded,
            color: Color(0xFF0B132B),
            size: 30,
          ),
        ),
      ),
    );
  }
}
