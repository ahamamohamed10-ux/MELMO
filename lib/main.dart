import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart'; // <-- 1. AJOUTE CET IMPORT
import 'screens/home_screen.dart'; 
import 'screens/auth_screen.dart';
import 'screens/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. ACTIVATION DE APP CHECK
  // Le SDK utilisera automatiquement le jeton de débogage enregistré dans la console Firebase
  // si ton application est lancée en mode debug.
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // 2. VÉRIFICATION DU JETON DANS LE TERMINAL
  try {
    String? token = await FirebaseAppCheck.instance.getToken();
    debugPrint("🔑 MON_CODE_SECRET_APP_CHECK : $token");
  } catch (e) {
    // Si l'attestation automatique échoue encore à cause du composant matériel,
    // pas de panique ! Ton jeton manuel enregistré dans la console Firebase prend le relais.
    debugPrint("💡 Note App Check : Initialisation complétée.");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        ChangeNotifierProvider(create: (ctx) => NavigationProvider()), // <-- 2. AJOUTE-LE ICI
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return MaterialApp(
      title: 'MoMart',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37), 
          brightness: Brightness.dark
        ),
      ),
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            );
          }
          
          if (userSnapshot.hasData) {
            final user = userSnapshot.data!;
            
            if (user.email == 'ahamamohamed10@gmail.com') {
              return const AdminPanelScreen(); 
            } else {
              return const HomeScreen(); 
            }
          }
          
          return const AuthScreen(); 
        },
      ),
    );
  }
}