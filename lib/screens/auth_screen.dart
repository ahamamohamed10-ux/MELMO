import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Contrôleurs pour récupérer le texte saisi
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false; // Affiche le cercle de chargement
  bool _isLogin = true;    // Alterne entre Connexion et Inscription

  // Fonction principale de connexion/inscription
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Vérification de base
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Connexion avec Firebase
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Inscription avec Firebase
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // Note : Le StreamBuilder dans main.dart détectera le changement 
      // et chargera automatiquement l'écran d'accueil.

    } on FirebaseAuthException catch (e) {
      // ✅ CORRECTION : Vérifie si l'écran est toujours là avant d'utiliser le context
      if (!mounted) return;

      String message = "Une erreur est survenue";
      if (e.code == 'user-not-found') message = "Aucun utilisateur trouvé pour cet email.";
      if (e.code == 'wrong-password') message = "Mot de passe incorrect.";
      if (e.code == 'email-already-in-use') message = "Cet email est déjà utilisé.";
      if (e.code == 'invalid-email') message = "Format d'email invalide.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // ✅ CORRECTION : Vérifie si l'écran est toujours là avant de changer l'état
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Nettoyage de la mémoire
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Colors.grey[100] 
          : Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou Icône de la boutique
              const Icon(Icons.shopping_bag_outlined, size: 100, color: Color(0xFFD4AF37)),
              const SizedBox(height: 15),
              Text(
                _isLogin ? "Bon retour !" : "Créer un compte",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // Champ Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Champ Mot de passe
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // Bouton d'action
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _isLogin ? 'SE CONNECTER' : 'S\'INSCRIRE',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 15),

              // Lien pour changer de mode
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? "Pas encore de compte ? Inscrivez-vous"
                      : "Déjà un compte ? Connectez-vous",
                  style: const TextStyle(color: Color(0xFFD4AF37)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}