import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomLoader extends StatefulWidget {
  final double size;
  const CustomLoader({super.key, this.size = 60});

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective
              ..rotateY(_controller.value * 2 * pi), // Y-axis rotation
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                height: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}
