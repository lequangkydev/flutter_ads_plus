import 'package:flutter/material.dart';

class CloseAdButton extends StatelessWidget {
  const CloseAdButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xff737373),
        ),
        child: const Icon(
          Icons.close,
          color: Color(0xFFDADADA),
          size: 12,
        ),
      ),
    );
  }
}
