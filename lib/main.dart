import 'package:flutter/material.dart';
import 'package:healthmobile/loginPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mvdiylyxtutbtumzdexm.supabase.co',
    anonKey: 'sb_publishable_K6j9BFSQ-XU4FLOMvqhLTA_ku1SHl8k',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Loginpage());
  }
}
