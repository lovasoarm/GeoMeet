import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class DotsPagination extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const DotsPagination({
    super.key,
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 12 : 8,
          height: currentIndex == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? AppColors.primarygreen
                : AppColors.cyanColor,
          ),
        ),
      ),
    );
  }
}
