import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/presentation/error/error_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/state/auth_state.dart';

/// Page de connexion pour l'application pharmacie DR-PHARMA.
/// 
/// Utilise [ConsumerStatefulWidget] pour accéder à Riverpod avec état local
/// (animations, contrôleurs de texte).
/// 
/// Architecture:
/// - État global (auth): géré par Riverpod via [authProvider]
/// - État local (UI): géré par [State] (animations, visibilité mot de passe)
/// - Effets secondaires: gérés par [ref.listen] (dialogs, navigation, snackbars)
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  // ══════════════════════════════════════════════════════════════════════════
  // ÉTAT LOCAL (UI uniquement)
  // ══════════════════════════════════════════════════════════════════════════
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  /// Flag pour éviter les doubles navigations pendant la redirection
  bool _isNavigating = false;

  /// Clé pour SharedPreferences
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedCredentials();
  }

  /// Charge les identifiants sauvegardés si "Se souvenir de moi" était activé
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      final savedEmail = prefs.getString(_savedEmailKey) ?? '';
      
      if (mounted && rememberMe && savedEmail.isNotEmpty) {
        setState(() {
          _rememberMe = true;
          _emailController.text = savedEmail;
        });
      }
    } catch (_) {
      // Ignorer les erreurs de SharedPreferences
    }
  }

  /// Sauvegarde ou supprime l'email selon le choix de l'utilisateur
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberMe) {
        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_savedEmailKey, _emailController.text.trim());
      } else {
        await prefs.remove(_rememberMeKey);
        await prefs.remove(_savedEmailKey);
      }
    } catch (_) {
      // Ignorer les erreurs de SharedPreferences
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GESTIONNAIRES D'ÉVÉNEMENTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Gère la soumission du formulaire de connexion.
  /// 
  /// Valide le formulaire avant d'appeler le provider.
  /// Le bouton est désactivé pendant le loading via [isLoading].
  void _handleLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Sauvegarder les credentials si "Se souvenir de moi" est activé
    _saveCredentials();

    ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  /// Callback pour [ref.listen] - réagit aux changements d'état auth.
  /// 
  /// ✅ SAFE: Appelé uniquement lors d'un CHANGEMENT d'état (pas à chaque rebuild)
  /// ✅ SAFE: Vérifie previous pour éviter les doubles triggers
  /// ✅ SAFE: Vérifie mounted avant toute interaction UI
  void _onAuthStateChanged(AuthState? previous, AuthState next) {
    debugPrint('🎯 [LoginPage] _onAuthStateChanged appelé');
    debugPrint('🎯 [LoginPage] previous: ${previous?.status}, next: ${next.status}');
    debugPrint('🎯 [LoginPage] errorMessage: ${next.errorMessage}');
    
    // Première émission (previous == null) → ignorer
    if (previous == null) {
      debugPrint('🎯 [LoginPage] previous == null, ignoré');
      return;
    }
    
    // Pas de changement de status → ignorer
    if (previous.status == next.status) {
      debugPrint('🎯 [LoginPage] Même status, ignoré');
      return;
    }

    debugPrint('🎯 [LoginPage] Changement détecté: ${previous.status} → ${next.status}');

    switch (next.status) {
      case AuthStatus.error:
        debugPrint('🎯 [LoginPage] → Appel _handleErrorState');
        _handleErrorState(next);
        break;
        
      case AuthStatus.authenticated:
        debugPrint('🎯 [LoginPage] → Appel _handleAuthenticatedState');
        _handleAuthenticatedState(next);
        break;
        
      default:
        debugPrint('🎯 [LoginPage] → Status non géré: ${next.status}');
        break;
    }
  }

  /// Gère l'affichage du dialogue d'erreur.
  void _handleErrorState(AuthState state) {
    debugPrint('🚨 [LoginPage] _handleErrorState appelé');
    debugPrint('🚨 [LoginPage] errorMessage: ${state.errorMessage}');
    debugPrint('🚨 [LoginPage] mounted: $mounted');
    
    if (state.errorMessage == null) {
      debugPrint('🚨 [LoginPage] errorMessage == null, abandon');
      return;
    }
    if (!mounted) {
      debugPrint('🚨 [LoginPage] !mounted, abandon');
      return;
    }
    
    debugPrint('🚨 [LoginPage] Appel ErrorHandler.showErrorDialog()...');
    
    // Utilisation du ErrorHandler centralisé
    ErrorHandler.showErrorDialog(
      context,
      state.errorMessage!,
      onDismiss: () {
        debugPrint('🚨 [LoginPage] Dialog fermé, clearError()');
        if (mounted) {
          ref.read(authProvider.notifier).clearError();
        }
      },
    );
    
    debugPrint('🚨 [LoginPage] showErrorDialog() appelé avec succès');
  }

  /// Gère la navigation après authentification réussie.
  void _handleAuthenticatedState(AuthState state) {
    // Protection contre double navigation
    if (_isNavigating) return;
    if (!mounted) return;
    
    _isNavigating = true;
    
    // Afficher le snackbar de bienvenue avec ErrorHandler
    ErrorHandler.showSuccessSnackBar(context, 'Bienvenue ${state.user?.name ?? ''} !');
    
    // Navigation immédiate (le snackbar reste visible)
    // Utiliser Future.microtask pour s'assurer que le snackbar est affiché
    Future.microtask(() {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ✅ ref.listen: Écoute les changements d'état pour les effets secondaires
    // Appelé UNIQUEMENT quand l'état CHANGE, pas à chaque rebuild
    ref.listen<AuthState>(authProvider, _onAuthStateChanged);

    // ✅ ref.watch: Rebuild uniquement quand nécessaire pour l'UI
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B8F6F), 
              const Color(0xFF0D5C46), 
              Colors.teal.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 16),
                  _buildTitle(),
                  const SizedBox(height: 8),
                  _buildSubtitle(),
                  const SizedBox(height: 48),
                  _buildLoginCard(isLoading),
                  const SizedBox(height: 32),
                  _buildCopyright(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS PRIVÉS (extraction pour lisibilité)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: const Icon(
          Icons.local_pharmacy_rounded, 
          size: 80, 
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Text(
        'DR-PHARMA', 
        style: TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: Colors.white, 
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Text(
        'Espace Pharmacie', 
        style: TextStyle(
          fontSize: 16, 
          color: Color(0xCCFFFFFF), // Colors.white with 80% opacity
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Text(
        '© 2024 DR-PHARMA', 
        style: TextStyle(
          color: Color(0x99FFFFFF), // Colors.white with 60% opacity
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000), // Colors.black with 20% opacity
              blurRadius: 20, 
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Connexion', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1B8F6F),
                ), 
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildRememberMeRow(),
              const SizedBox(height: 24),
              _buildLoginButton(isLoading),
              const SizedBox(height: 16),
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre email';
        }
        if (!value.contains('@')) {
          return 'Veuillez entrer un email valide';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre mot de passe';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeRow() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (v) => setState(() => _rememberMe = v ?? false),
              activeColor: const Color(0xFF1B8F6F),
            ),
            const Text('Se souvenir de moi'),
          ],
        ),
        TextButton(
          onPressed: () {
            // TODO: Implémenter la récupération de mot de passe
          },
          child: const Text(
            'Mot de passe oublié ?', 
            style: TextStyle(color: Color(0xFF1B8F6F)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B8F6F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0x991B8F6F), // 60% opacity
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24, 
                width: 24, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Se connecter', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Vous n'avez pas de compte ?"),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text(
            "S'inscrire", 
            style: TextStyle(
              color: Color(0xFF1B8F6F), 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
