
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AdLoading extends StatelessWidget {
  const AdLoading({
    super.key, this.width, this.height, this.padding,
  });

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: padding,
      child: Shimmer.fromColors(
        period: const Duration(milliseconds: 750),
        baseColor: Colors.white,
        highlightColor: Colors.white,
        child: const ColoredBox(color: Colors.white),
      ),
    );
  }
}