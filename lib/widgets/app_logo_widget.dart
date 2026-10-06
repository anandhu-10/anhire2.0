import 'package:flutter/material.dart';

class AppLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final double textSize;

  const AppLogoWidget({
    super.key,
    this.size = 42,
    this.showText = true,
    this.textSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: const Color(0x556C5CE7),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.25),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF6C5CE7),
                  child: Icon(
                    Icons.school,
                    color: Colors.white,
                    size: size * 0.6,
                  ),
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'ANHIRE',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
