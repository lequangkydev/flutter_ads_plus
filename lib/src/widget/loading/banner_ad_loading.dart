import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'custom_placeholder.dart';

class BannerAdLoading extends StatelessWidget {
  const BannerAdLoading({
    super.key,
    this.height = 60,
    this.backgroundColor,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
  });

  final double height;
  final Color? backgroundColor;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: backgroundColor ?? Colors.white,
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor ?? Colors.grey.shade300,
        highlightColor: shimmerHighlightColor ?? Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CustomPlaceholder(
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPlaceholder(
                      height: 12,
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    CustomPlaceholder(
                      width: 100,
                      height: 12,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
