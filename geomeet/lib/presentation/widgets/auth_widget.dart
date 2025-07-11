import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/views/auth/auth_viewmodel.dart';
import '../../app/routes.dart'; 
import '../../core/constants/colors.dart';

class AuthBody extends StatefulWidget {
  final bool isLogin;
  final VoidCallback? onToggleAuthMode;

  const AuthBody({
    super.key,
    required this.isLogin,
    this.onToggleAuthMode,
  });

  @override
  State<AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<AuthBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context, listen: true);
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Section image avec vague
                ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    width: double.infinity,
                    height: widget.isLogin 
                        ? screenSize.height * 0.4 
                        : screenSize.height * 0.3,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/auth/auth_img.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                // Section formulaire
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          widget.isLogin ? "Connexion" : "Créer un compte",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primarygreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        
                        if (!widget.isLogin) ...[
                          _buildTextField(
                            controller: _usernameController,
                            label: "Nom d'utilisateur",
                            icon: Icons.person_outline,
                            validator: (value) => value?.isEmpty ?? true 
                                ? 'Veuillez entrer un nom d\'utilisateur' 
                                : null,
                          ),
                          const SizedBox(height: 15),
                        ],
                        
                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        _buildTextField(
                          controller: _passwordController,
                          label: "Mot de passe",
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un mot de passe';
                            }
                            if (value.length < 6) {
                              return '6 caractères minimum';
                            }
                            return null;
                          },
                        ),
                        
                        if (!widget.isLogin) ...[
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: "Confirmer le mot de passe",
                            icon: Icons.lock_outlined,
                            obscureText: true,
                            validator: (value) => value != _passwordController.text
                                ? 'Les mots de passe ne correspondent pas'
                                : null,
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        if (widget.isLogin) 
                          _buildRememberMeRow(context),
                        
                        const SizedBox(height: 20),
                        
                        if (viewModel.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              viewModel.error!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        
                        _buildAuthButton(viewModel),
                        const SizedBox(height: 20),
                        _buildToggleAuthText(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (viewModel.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        
      ),
    );
  }

  Widget _buildRememberMeRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            Text(
              "Se souvenir de moi",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        TextButton(
          onPressed: () => _handleForgotPassword(),
          child: Text(
            "Mot de passe oublié?",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primarygreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButton(AuthViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarygreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: viewModel.isLoading
            ? null
            : () => _handleAuthAction(viewModel),
        child: Text(
          widget.isLogin ? "Se connecter" : "S'inscrire",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleAuthText() {
    return Center(
      child: TextButton(
        onPressed: widget.onToggleAuthMode,
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: widget.isLogin 
                    ? "Pas encore de compte? " 
                    : "Déjà un compte? ",
              ),
              TextSpan(
                text: widget.isLogin ? "S'inscrire" : "Se connecter",
                style: TextStyle(
                  color: AppColors.primarygreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuthAction(AuthViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus(); 

    try {
      bool success;
      if (widget.isLogin) {
        success = await viewModel.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        success = await viewModel.register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _usernameController.text.trim(),
        );
      }
      
      if (success && mounted) {
        if (!widget.isLogin) {
       
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inscription réussie! Bienvenue ${_usernameController.text}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
       
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
             Navigator.of(context)
                                          .pushNamed(
                                              AppRoutes.homeview);
          }
        } else {
         
          Navigator.pushNamed(context,AppRoutes.homeview);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre email')),
      );
      return;
    }

    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    try {
      await viewModel.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.8, 
      size.width * 0.5, size.height * 0.9,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height, 
      size.width, size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}