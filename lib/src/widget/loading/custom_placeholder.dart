import 'package:flutter/material.dart';

class CustomPlaceholder extends Container {
  CustomPlaceholder({
    super.key,
    super.width,
    super.height,
    super.color,
  });

  @override
  Decoration? get decoration => BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
      );
}
