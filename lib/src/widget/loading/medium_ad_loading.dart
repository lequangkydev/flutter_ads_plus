import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'custom_placeholder.dart';

class MediumAdLoading extends StatelessWidget {
  const MediumAdLoading({
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
          height: height,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CustomPlaceholder(
                      width: 130,
                      height: double.infinity,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: CustomPlaceholder(
                              width: double.infinity,
                              height: 18,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Expanded(
                            child: CustomPlaceholder(
                              width: double.infinity,
                              height: 18,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Expanded(
                            child: CustomPlaceholder(
                              width: double.infinity,
                              height: 18,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Expanded(
                            child: CustomPlaceholder(
                              width: double.infinity,
                              height: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
