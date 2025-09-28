import 'package:flutter/material.dart';
import 'auth_service.dart'; // Make sure this import is correct

class LoginPage extends StatefulWidget {
  final VoidCallback? onToggleRegister; // Optional: To switch to register page

  const LoginPage({super.key, this.onToggleRegister});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); // Added for form validation
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _tokenDisplay; // For displaying the token, not for auth state
  bool _isLoading = false;
  String? _inlineErrorMessage;
  bool _obscurePassword = true;

  // Define your color scheme (consistent with RegisterPage)
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFF4FC3F7);
  static const Color textColor = Color(0xFF2D3748);
  static const Color subtleTextColor = Color(0xFF718096);
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Colors.green;
  static const Color cardBackgroundColor = Colors.white;
  static const Color inputBorderColor = Colors.grey;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _inlineErrorMessage = "Please correct the errors above.";
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _inlineErrorMessage = null;
      _tokenDisplay = null;
    });

    try {
      final token = await AuthService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (token != null) {
        // ✅ Successful login
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Clean the Exception prefix
        _inlineErrorMessage = e.toString().replaceFirst("Exception: ", "");
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_inlineErrorMessage!),
          backgroundColor: errorColor,
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your username and password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: subtleTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_inlineErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _inlineErrorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: errorColor, fontWeight: FontWeight.w500),
                      ),
                    ),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildUsernameField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 12),

                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor))
                            : _buildLoginButton(),
                      ],
                    ),
                  ),

                  if (_tokenDisplay != null) // Display token if available
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        "Token: $_tokenDisplay",
                        style: const TextStyle(color: subtleTextColor, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),
                  _buildRegisterToggle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      keyboardType: TextInputType.text, // Or emailAddress if username is email
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Username',
        hintText: 'Enter your username',
        prefixIcon: Icon(Icons.person_outline, color: primaryColor.withOpacity(0.8), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cardBackgroundColor,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderColor.withOpacity(0.5)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your username';
        }
        return null;
      },
      style: const TextStyle(color: textColor),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor.withOpacity(0.8), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: subtleTextColor,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cardBackgroundColor,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderColor.withOpacity(0.5)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        // You might add length validation if your backend requires it
        // if (value.length < 6) {
        //   return 'Password must be at least 6 characters';
        // }
        return null;
      },
      onFieldSubmitted: (_) => _isLoading ? null : _login(),
      style: const TextStyle(color: textColor),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRegisterToggle() {
    // If you don't have a RegisterPage or the onToggleRegister callback,
    // you can remove this method and its call from the build method.
    if (widget.onToggleRegister == null) {
      return const SizedBox.shrink(); // Don't show if no way to toggle
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?", style: TextStyle(color: subtleTextColor)),
        TextButton(
          onPressed: widget.onToggleRegister,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            foregroundColor: accentColor,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}
