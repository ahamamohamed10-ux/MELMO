import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Utilisation de watch pour que l'UI se mette à jour quand le thème change
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