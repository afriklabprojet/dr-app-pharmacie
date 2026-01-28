import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/state/auth_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isRedirecting = false; // Prevent multiple redirections

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), 
      end: Offset.zero
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submit() {
    debugPrint('🔘 [LoginPage] _submit() appelé');
    
    // Prevent double-tap / multiple submissions
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading || _isRedirecting) {
      debugPrint('⚠️ [LoginPage] Submission ignorée - déjà en cours');
      return;
    }
    
    debugPrint('🔘 [LoginPage] Email: ${_emailController.text}');
    debugPrint('🔘 [LoginPage] Form valid: ${_formKey.currentState?.validate()}');
    
    if (_formKey.currentState!.validate()) {
      debugPrint('🔘 [LoginPage] Formulaire validé, appel de login...');
      ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    } else {
      debugPrint('❌ [LoginPage] Validation du formulaire échouée');
    }
  }

  /// Convertit les messages d'erreur techniques en messages lisibles pour l'utilisateur
  String _getReadableErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    if (errorLower.contains('invalid credentials') || errorLower.contains('identifiants')) {
      return 'Email ou mot de passe incorrect.\n\nVérifiez vos identifiants et réessayez.';
    }
    if (errorLower.contains('not approved') || errorLower.contains('non approuvé')) {
      return 'Votre compte n\'a pas encore été approuvé par l\'administrateur.\n\nVeuillez patienter ou contacter le support.';
    }
    if (errorLower.contains('network') || errorLower.contains('connexion')) {
      return 'Problème de connexion internet.\n\nVérifiez votre connexion et réessayez.';
    }
    if (errorLower.contains('email') && errorLower.contains('not found')) {
      return 'Aucun compte n\'existe avec cet email.\n\nVérifiez l\'adresse ou créez un compte.';
    }
    if (errorLower.contains('disabled') || errorLower.contains('désactivé')) {
      return 'Ce compte a été désactivé.\n\nContactez le support pour plus d\'informations.';
    }
    if (errorLower.contains('unauthorized') || errorLower.contains('401')) {
      return 'Session expirée ou identifiants invalides.\n\nVeuillez réessayer.';
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      debugPrint('👂 [LoginPage] Auth state changed: ${previous?.status} -> ${next.status}');
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        debugPrint('❌ [LoginPage] Erreur affichée: ${next.errorMessage}');
        if (_isRedirecting && mounted) {
          setState(() => _isRedirecting = false);
        }
        
        // Déterminer le type d'erreur pour afficher un dialogue approprié
        final errorMessage = next.errorMessage!;
        final isAccountPending = errorMessage.contains('attente') || 
                                  errorMessage.contains('pending') ||
                                  errorMessage.contains('PENDING');
        final isAccountSuspended = errorMessage.contains('suspendu') || 
                                    errorMessage.contains('suspended');
        final isAccountRejected = errorMessage.contains('refusé') || 
                                   errorMessage.contains('rejected');
        final isInvalidCredentials = errorMessage.contains('identifiants') || 
                                      errorMessage.contains('incorrect') ||
                                      errorMessage.contains('credentials');
        
        // Choisir l'icône et la couleur selon le type d'erreur
        IconData icon;
        Color iconColor;
        String title;
        
        if (isAccountPending) {
          icon = Icons.hourglass_top_rounded;
          iconColor = Colors.orange;
          title = 'Compte en attente';
        } else if (isAccountSuspended) {
          icon = Icons.block_rounded;
          iconColor = Colors.red;
          title = 'Compte suspendu';
        } else if (isAccountRejected) {
          icon = Icons.cancel_rounded;
          iconColor = Colors.red;
          title = 'Inscription refusée';
        } else if (isInvalidCredentials) {
          icon = Icons.password_rounded;
          iconColor = Colors.orange;
          title = 'Identifiants incorrects';
        } else {
          icon = Icons.error_outline;
          iconColor = Colors.red;
          title = 'Échec de connexion';
        }
        
        // Afficher un dialogue d'erreur approprié
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getReadableErrorMessage(errorMessage),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                if (isAccountPending) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Vous recevrez un email dès que votre compte sera approuvé.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (isAccountSuspended || isAccountRejected)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // TODO: Ouvrir l'écran de contact support
                  },
                  child: const Text('Contacter le support'),
                ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
      }
      if (next.status == AuthStatus.authenticated && !_isRedirecting) {
        debugPrint('✅ [LoginPage] Authentifié - affichage message de bienvenue');
        if (mounted) {
          setState(() => _isRedirecting = true);
        }
        // Afficher un message de bienvenue avant la redirection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bienvenue ${next.user?.name ?? ''} !',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
        // Délai pour que l'utilisateur voie le message de bienvenue
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            context.go('/dashboard');
          }
        });
      }
    });


    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading || _isRedirecting;
    
    debugPrint('🖼️ [LoginPage] build() - status: ${authState.status}, isLoading: $isLoading');

    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo section
              Icon(
                Icons.local_pharmacy_rounded,
                size: 80,
                color: Colors.teal[700],
              ),
              const SizedBox(height: 16),
              Text(
                'DR-PHARMA',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.teal[900],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
              Text(
                'Espace Pharmacien',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.teal[600],
                    ),
              ),
              const SizedBox(height: 40),

              // Form section
              Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Connexion',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Adresse Email',
                            hintText: 'pharmacien@exemple.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.teal, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            // Basic email validation regex can be added here
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.teal, width: 2),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal[700],
                            ),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Connexion en cours...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Vous n'avez pas de compte ?",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed:
                        isLoading ? null : () => context.push('/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Créer un compte'),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}

