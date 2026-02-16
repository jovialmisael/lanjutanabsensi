import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Setup Breathe Animation
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutCubic),
    );

    // Timer Navigasi
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _goToLogin();
      }
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 2000),
        reverseTransitionDuration: const Duration(milliseconds: 2000),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
              parent: animation, 
              curve: const Interval(0.0, 0.6, curve: Curves.easeIn)
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // --- HERO LOGO + BREATHE ANIMATION ---
            ScaleTransition(
              scale: _breatheAnimation,
              child: Hero(
                tag: 'app_logo',
                // Optimasi Rendering Hero: Mencegah rebuild berat saat terbang
                flightShuttleBuilder: (
                  BuildContext flightContext,
                  Animation<double> animation,
                  HeroFlightDirection flightDirection,
                  BuildContext fromHeroContext,
                  BuildContext toHeroContext,
                ) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                       // Gunakan image yang sudah dicache di memori
                       return Image.asset(
                        "lib/assets/sbb-removebg-preview.png",
                        fit: BoxFit.contain,
                        cacheWidth: 300, // KUNCI: Samakan dengan LoginScreen
                      );
                    }
                  );
                },
                child: Image.asset(
                  "lib/assets/sbb-removebg-preview.png",
                  width: 250,
                  fit: BoxFit.contain,
                  cacheWidth: 300, // KUNCI: Resize gambar di memori sejak awal
                ),
              ),
            ),

            const SizedBox(height: 50),

            // --- LOADING ANIMATION ---
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFD32F2F),
              ),
            ),

            const Spacer(),
            
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                "Versi 1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}