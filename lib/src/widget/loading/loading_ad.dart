import 'package:flutter/cupertino.dart';

class MyLoadingAd extends StatelessWidget {
  const MyLoadingAd({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoActivityIndicator(),
    );
  }
}
