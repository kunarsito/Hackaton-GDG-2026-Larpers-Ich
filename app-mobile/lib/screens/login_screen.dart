import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';

/// Inicio de sesión y registro. Igual en móvil y web: tarjeta centrada de
/// ancho máximo 420 px con scroll para que el teclado táctil no la tape.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _serverUnreachable = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _universityCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _serverUnreachable = false;
    });
    try {
      if (_isRegister) {
        await _api.register(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          university: _universityCtrl.text,
        );
      } else {
        await _api.login(email: _emailCtrl.text, password: _passwordCtrl.text);
      }
      if (mounted) widget.onLoggedIn();
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _serverUnreachable = e.offline;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useDemoAccount() {
    setState(() {
      _isRegister = false;
      _emailCtrl.text = ApiService.demoEmail;
      _passwordCtrl.text = ApiService.demoPassword;
    });
    _submit();
  }

  void _continueOffline() {
    _api.enterOfflineDemo();
    widget.onLoggedIn();
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppTheme.greenishGray),
      filled: true,
      fillColor: AppTheme.darkSiliconDeep,
      labelStyle: const TextStyle(color: AppTheme.greenishGray, fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.circuitTrace),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.phosphorGreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.alertRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.alertRed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solderMask,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.darkSilicon,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.circuitTrace),
                ),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.memory_rounded, color: AppTheme.phosphorGreen),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '> FARO_DEV // CAMPUS',
                                style: TextStyle(
                                  fontFamily: AppTheme.monoFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.phosphorGreen,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRegister ? 'Crea tu cuenta' : 'Inicia sesión para continuar',
                          style: const TextStyle(color: AppTheme.greenishGray, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        if (_isRegister) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            style: const TextStyle(color: AppTheme.boneWhite),
                            decoration: _decoration('Nombre o usuario', Icons.person_outline),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu nombre.' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _universityCtrl,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppTheme.boneWhite),
                            decoration: _decoration('Universidad (opcional)', Icons.school_outlined),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          style: const TextStyle(color: AppTheme.boneWhite),
                          decoration: _decoration('Correo electrónico', Icons.alternate_email),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Escribe tu correo.';
                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                              return 'Correo no válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: [
                            _isRegister ? AutofillHints.newPassword : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) => _loading ? null : _submit(),
                          style: const TextStyle(color: AppTheme.boneWhite),
                          decoration: _decoration('Contraseña', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 18,
                                color: AppTheme.greenishGray,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Escribe tu contraseña.';
                            if (_isRegister && v.length < 8) return 'Mínimo 8 caracteres.';
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.alertRed, fontSize: 13),
                          ),
                        ],
                        if (_serverUnreachable) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _continueOffline,
                            icon: const Icon(Icons.cloud_off, size: 16),
                            label: const Text('Continuar sin conexión (modo demo)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.solderGold,
                              side: const BorderSide(color: AppTheme.solderGold),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.phosphorGreen,
                            foregroundColor: AppTheme.solderMask,
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.solderMask,
                                  ),
                                )
                              : Text(
                                  _isRegister ? 'Crear cuenta' : 'Entrar',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _isRegister = !_isRegister;
                                    _error = null;
                                    _serverUnreachable = false;
                                  }),
                          child: Text(
                            _isRegister ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
                            style: const TextStyle(color: AppTheme.phosphorGreen),
                          ),
                        ),
                        if (!_isRegister) ...[
                          const Divider(color: AppTheme.circuitTrace, height: 24),
                          TextButton.icon(
                            onPressed: _loading ? null : _useDemoAccount,
                            icon: const Icon(Icons.bolt, size: 16, color: AppTheme.solderGold),
                            label: const Text(
                              'Entrar con cuenta demo (Ada Dev)',
                              style: TextStyle(color: AppTheme.solderGold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
