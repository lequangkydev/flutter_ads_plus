import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'custom_placeholder.dart';

class LargeAdLoading extends StatelessWidget {
  const LargeAdLoading({
    super.key,
    this.height,
    this.padding,
    this.backgroundColor = Colors.white,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
  });

  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      width: MediaQuery.of(context).size.width,
      color: backgroundColor,
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor ?? Colors.grey.shade300,
        highlightColor: shimmerHighlightColor ?? Colors.grey.shade100,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CustomPlaceholder(
                    width: 42,
                    height: 42,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        CustomPlaceholder(
                          width: double.infinity,
                          height: 18,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        CustomPlaceholder(
                          width: double.infinity,
                          height: 18,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: CustomPlaceholder(
                  width: 0.7 * MediaQuery.of(context).size.width,
                  height: double.infinity,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              CustomPlaceholder(
                width: MediaQuery.of(context).size.width,
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
