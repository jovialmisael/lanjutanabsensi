import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'mobil_home_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Controller
  final _nikController = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Animation Controllers
  late AnimationController _entryController; // Untuk Garis Merah
  late Animation<double> _entryAnimation;

  late AnimationController _formFadeController; // Untuk Form (Input/Text)
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation; // Animasi Geser Naik

  // State
  bool _isLoading = false;
  final ValueNotifier<bool> _obscurePasswordNotifier = ValueNotifier(true);

  // Colors
  final Color _brandRed = const Color(0xFFD32F2F);
  final Color _brandBlack = const Color(0xFF212121);

  // Logo Config
  final double _logoWidth = 260.0;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animasi Garis (Lebih Lambat & Smooth)
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Diperlambat jadi 1.5 detik
      vsync: this,
    );

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    // 2. Setup Animasi Form (Fade + Slide Up)
    _formFadeController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Diperlambat jadi 1.2 detik
      vsync: this,
    );

    _formFadeAnimation = CurvedAnimation(
      parent: _formFadeController,
      curve: Curves.easeOutQuart, // Curve ini sangat halus di akhir (decelerate)
    );

    // Animasi Geser dari bawah sedikit ke posisi asli
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // Mulai dari 5% lebih bawah
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formFadeController,
      curve: Curves.easeOutQuart,
    ));

    // KUNCI SMOOTHNESS:
    // Tunggu Hero Animation hampir selesai (1600ms dari total 2000ms splash)
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _entryController.forward(); // Jalankan Garis
        _formFadeController.forward(); // Munculkan Form (Fade + Slide)
      }
    });

    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
  }

  @override
  void dispose() {
    _entryController.dispose();
    _formFadeController.dispose();
    _nikController.dispose();
    _passController.dispose();
    _obscurePasswordNotifier.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_nikController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIK dan Password harus diisi"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    LoginResponse res = await _apiService.login(_nikController.text, _passController.text);

    if (res.success && res.accessToken != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.accessToken!);
      await prefs.setString('name', res.name ?? "User");
      await prefs.setString('nik', _nikController.text);

      if (res.isOldPass) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordScreen(token: res.accessToken!)),
        );
        return;
      }

      var profileData = await _apiService.getProfile(res.accessToken!);
      setState(() => _isLoading = false);

      if (profileData != null) {
        bool isMobile = false;
        if (profileData['position'] != null && profileData['position']['is_mobile'] == 1) {
          isMobile = true;
        } else if (profileData['position'] != null && profileData['position']['is_mobile'] == true) {
          isMobile = true;
        }

        if (!mounted) return;

        if (isMobile) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MobileHomeScreen(
                    token: res.accessToken!,
                    name: res.name ?? "User"
                )
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(
                    token: res.accessToken!,
                    name: res.name ?? "User"
                )
            ),
          );
        }
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(token: res.accessToken!, name: res.name ?? "User")),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // --- LOGO IMAGE (Always Visible for Hero) ---
                  RepaintBoundary(
                    child: Center(
                      child: Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          "lib/assets/sbb-removebg-preview.png",
                          height: 100,
                          width: 250,
                          cacheWidth: 300, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  // --- ANIMATED LINE ---
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child: Center(
                      child: SizedBox(
                        width: _logoWidth, 
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _entryAnimation,
                            builder: (context, child) {
                              double currentWidth = _logoWidth * _entryAnimation.value;
                              return Container(
                                height: 4,
                                width: currentWidth,
                                decoration: BoxDecoration(
                                  color: _brandRed,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _brandRed.withOpacity(0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- FORM CONTENT (FADE IN + SLIDE UP) ---
                  FadeTransition(
                    opacity: _formFadeAnimation,
                    child: SlideTransition(
                      position: _formSlideAnimation, // Menambahkan efek geser naik yang elegan
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- TITLE ---
                          RepaintBoundary(
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [_brandRed, _brandBlack],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: const Text(
                                "ABSENSI",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  
                          const SizedBox(height: 8),
                          Text(
                            "Masukan Data Diri",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                  
                          const SizedBox(height: 40),
                  
                          // --- INPUT FIELDS ---
                          _buildNormalTextField(
                            controller: _nikController,
                            label: "Nomor Induk Karyawan (NIK)",
                            icon: Icons.badge_outlined,
                            primaryColor: _brandRed,
                          ),
                          const SizedBox(height: 20),
                  
                          ValueListenableBuilder<bool>(
                            valueListenable: _obscurePasswordNotifier,
                            builder: (context, isObscure, child) {
                              return _buildPasswordTextField(
                                controller: _passController,
                                label: "Kata Sandi",
                                isObscure: isObscure,
                                primaryColor: _brandRed,
                                onToggleVisibility: () {
                                  _obscurePasswordNotifier.value = !isObscure;
                                },
                              );
                            },
                          ),
                  
                          const SizedBox(height: 32),
                  
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandRed,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: _brandRed.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                disabledBackgroundColor: _brandRed.withOpacity(0.6),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                "MASUK",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ),
                  
                          const SizedBox(height: 40),
                  
                          const Center(
                            child: Text(
                              "Versi 1.0.0",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required Color primaryColor,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: TextInputType.visiblePassword,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          prefixIcon: Icon(Icons.lock_outline, color: primaryColor.withOpacity(0.8)),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[400],
            ),
            onPressed: onToggleVisibility,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }
}