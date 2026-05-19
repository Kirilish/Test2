import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class ZapshopGarageApp extends StatelessWidget {
  const ZapshopGarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zapshop Garage',
      theme: buildTheme(),
      routerConfig: appRouter,
    );
  }
}
