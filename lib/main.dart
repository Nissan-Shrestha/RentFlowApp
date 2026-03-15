import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_flow_app/screens/auth/splash_screen.dart';
import 'package:rent_flow_app/viewmodels/property_viewmodel.dart';
import 'package:rent_flow_app/viewmodels/tenant_viewmodel.dart';
import 'package:rent_flow_app/viewmodels/payment_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PropertyViewModel()),
        ChangeNotifierProvider(create: (_) => TenantViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
      ],
      child: const RentFlowApp(),
    ),
  );
}

class RentFlowApp extends StatelessWidget {
  const RentFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
