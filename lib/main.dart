import 'package:donaid/Donor/categories_screen.dart';
import 'package:donaid/Organization/organization_dashboard.dart';
import 'package:donaid/Registration/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get_storage/get_storage.dart';
import 'authentication.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'Registration/donor_registration_screen.dart';
import 'Registration/organization_registration_screen.dart';
import 'Donor/donor_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51KTuiGEvfimLlZrsjvlq3mE1JEa8nGiejkGVgw9MvqJd9viDPIXCbUGbWp1QaXf50sQIQs3MNWlVjp99VAruB0qW00xrE9kMs7';
  await Firebase.initializeApp();
  await GetStorage.init();
  await Auth.getCurrentUser();
  runApp(const Donaid());
}

class Donaid extends StatelessWidget {
  const Donaid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: EasyLoading.init(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: HomeScreen.id,
      routes: {
        HomeScreen.id: (context) => const HomeScreen(),
        LoginScreen.id: (context) => const LoginScreen(),
        RegistrationScreen.id: (context) => const RegistrationScreen(),
        DonorRegistrationScreen.id: (context) => const DonorRegistrationScreen(),
        OrganizationRegistrationScreen.id: (context) => const OrganizationRegistrationScreen(),
        DonorDashboard.id: (context) => const DonorDashboard(),
        OrganizationDashboard.id: (context) => const OrganizationDashboard(),
        CategoriesScreen.id: (context) => const CategoriesScreen(),
      },
    );
  }
}


