import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shake_detector/shake_detector.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/views/auth/sign_in_view.dart';
import 'package:shiftipoz/views/profile_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  String _input = "0";
  String _output = "0.00";

  String _selectedCategory = "Length";
  String _fromUnit = "Meters";
  String _toUnit = "Feet";

  bool _isSwapped = false;

  late ShakeDetector _detector;

  // Horizontal category controller
  late final ScrollController _categoryScrollController;

  // ---------------- DATA ----------------

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

  // Approx chip widths to make auto-centering feel right.
  // (Since labels have varying width)
  final List<double> _chipWidths = [110, 110, 110, 100];

  // ---------------- LIFECYCLE ----------------

  @override
  void initState() {
    super.initState();

    _categoryScrollController = ScrollController();

    _detector = ShakeDetector.autoStart(
      onShake: () {
        setState(() {
          _input = "0";
          _calculate();
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cleared by shake!"),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1C2541),
          ),
        );
      },
      shakeThresholdGravity: 2.7,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateCategoryToSelection();
    });
  }

  @override
  void dispose() {
    _detector.stopListening();
    _categoryScrollController.dispose();
    super.dispose();
  }

  // ---------------- LOGIC ----------------

  void _onKeyPress(String value) {
    setState(() {
      if (value == '⌫') {
        _input = _input.length > 1
            ? _input.substring(0, _input.length - 1)
            : "0";
      } else if (value == '.') {
        if (!_input.contains('.')) {
          _input += '.';
        }
      } else {
        _input = _input == "0" ? value : _input + value;
      }

      _calculate();
    });
  }

  void _calculate() {
    final inputVal = double.tryParse(_input) ?? 0;
    double result;

    if (_selectedCategory == 'Temp') {
      result = _convertTemperature(inputVal, _fromUnit, _toUnit);
    } else {
      final baseValue = inputVal / _unitData[_selectedCategory]![_fromUnit]!;
      result = baseValue * _unitData[_selectedCategory]![_toUnit]!;
    }

    _output = result.toStringAsFixed(2);
  }

  double _convertTemperature(double val, String from, String to) {
    if (from == to) return val;

    double celsius;

    if (from == 'Fahrenheit') {
      celsius = (val - 32) * 5 / 9;
    } else if (from == 'Kelvin') {
      celsius = val - 273.15;
    } else {
      celsius = val;
    }

    if (to == 'Fahrenheit') {
      return (celsius * 9 / 5) + 32;
    }

    if (to == 'Kelvin') {
      return celsius + 273.15;
    }

    return celsius;
  }

  void _handleSwap() {
    setState(() {
      _isSwapped = !_isSwapped;

      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;

      _calculate();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _fromUnit = _unitData[_selectedCategory]!.keys.first;
      _toUnit = _unitData[_selectedCategory]!.keys.elementAt(1);
      _calculate();
    });

    _animateCategoryToSelection();
  }

  // ---- FIXED TAB AUTO SCROLL / ANIMATION ----
  // Length/Weight => animates left
  // Volume/Temp => animates right
  void _animateCategoryToSelection() {
    if (!_categoryScrollController.hasClients) return;

    final index = _categories.indexOf(_selectedCategory);

    double targetOffset = 0;

    if (index <= 1) {
      // Left side categories
      targetOffset = 0;
    } else {
      // Right side categories
      final totalBefore = _chipWidths
          .take(index)
          .fold<double>(0, (a, b) => a + b);

      targetOffset = totalBefore - 80;
    }

    final maxScroll = _categoryScrollController.position.maxScrollExtent;

    if (targetOffset > maxScroll) {
      targetOffset = maxScroll;
    }

    if (targetOffset < 0) {
      targetOffset = 0;
    }

    _categoryScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showUnitPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final units = _unitData[_selectedCategory]!.keys.toList();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: units.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  units[index],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    if (isFrom) {
                      _fromUnit = units[index];
                    } else {
                      _toUnit = units[index];
                    }

                    _calculate();
                  });

                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewPadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: screenHeight - viewPadding.top - viewPadding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(children: [_buildHeader(), _buildCategorySelector()]),

                SizedBox(
                  height: 310,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        top: _isSwapped ? 160 : 0,
                        left: 24,
                        right: 24,
                        child: _buildUnitCard("From", _fromUnit, _input, true),
                      ),

                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        top: _isSwapped ? 0 : 160,
                        left: 24,
                        right: 24,
                        child: _buildUnitCard("To", _toUnit, _output, false),
                      ),

                      Center(child: _buildSwapButton()),
                    ],
                  ),
                ),

                _buildNumericKeypad(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'SHIFTIPOZ',
            style: TextStyle(
              color: Color(0xFFC0C0C0),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ref.watch(authControllerProvider).value != null
                      ? ProfileView()
                      : SignInView(),
                ),
              );
            },
            icon: Icon(
              ref.watch(authControllerProvider).value != null
                  ? Icons.logout_outlined
                  : Icons.account_circle_outlined,
              color: const Color(0xFFC0C0C0).withValues(alpha: 0.6),
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = _selectedCategory == category;

          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFC0C0C0).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isActive ? const Color(0xFFC0C0C0) : Colors.white10,
                ),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white30,
                    fontWeight: FontWeight.bold,
                  ),
                  child: Text(category),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitCard(String label, String unit, String value, bool isInput) {
    return GestureDetector(
      onLongPress: !isInput
          ? () async {
              await Clipboard.setData(ClipboardData(text: value));

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Result copied!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                  onTap: () => _showUnitPicker(isInput),
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
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isInput ? 32 : 42,
                  fontWeight: isInput ? FontWeight.w300 : FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 1,
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

  Widget _buildNumericKeypad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];

    return Container(
      padding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.8,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => _onKeyPress(keys[index]),
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Text(
                keys[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
