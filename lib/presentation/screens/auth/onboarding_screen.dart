import 'package:flutter/material.dart';
import 'package:bridgetalk/presentation/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Connect with Family',
      'description': 'Build stronger bonds through shared emotions.',
      'color': const Color(0xFFFFEBE0),
      'accent': const Color(0xFFFF6B35),
    },
    {
      'title': 'Understand Moods',
      'description': 'See each other’s emotions through emojis.',
      'color': const Color(0xFFECF6FF),
      'accent': const Color(0xFF4A89DC),
    },
    {
      'title': 'Start Your Journey',
      'description': 'Improve communication with emotional insights.',
      'color': const Color(0xFFE6F9EE),
      'accent': const Color(0xFF2ECC71),
    },
  ];

  @override
  void initState() {
    super.initState();

    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Content animation controller
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _updateBackgroundColorAnimation();
    _contentAnimationController.forward();
  }

  void _updateBackgroundColorAnimation() {
    Color beginColor = _slides[_currentPage]['color'];
    Color endColor = _slides[(_currentPage + 1) % _slides.length]['color'];

    _backgroundColorAnimation = ColorTween(
      begin: beginColor,
      end: endColor,
    ).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color:
                      _backgroundColorAnimation.value ??
                      _slides[_currentPage]['color'],
                ),
              );
            },
          ),

          // Background decorative elements
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.28,
            child: Container(
              height: size.width * 0.7,
              width: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _slides[_currentPage]['accent'].withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.15,
            left: -size.width * 0.1,
            child: Container(
              height: size.width * 0.7,
              width: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _slides[_currentPage]['accent'].withOpacity(0.05),
              ),
            ),
          ),

          // Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
                _updateBackgroundColorAnimation();
                _backgroundAnimationController.reset();
                _backgroundAnimationController.forward();
                _contentAnimationController.reset();
                _contentAnimationController.forward();
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSlide(index),
              );
            },
          ),

          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () async {
                await completeOnboarding();
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },

              child: Text(
                'Skip',
                style: TextStyle(
                  color: _slides[_currentPage]['accent'],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: TextButton(
              onPressed: () async {
                await completeOnboarding();
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/icons/BridgeTalk.png",
                    height: 30,
                    width: 30,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'BridgeTalk',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicators(),
                  ),
                  const SizedBox(height: 30),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        } else {
                          await completeOnboarding();
                          Navigator.pushReplacement(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _slides[_currentPage]['accent'],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _slides[index]['accent'].withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _slides[index]['accent'].withOpacity(0.15),
                  ),
                  child: Image.asset(
                    "assets/images/icon.png",
                    height: 150,
                    width: 150,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            _slides[index]['title'],
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _slides[index]['accent'],
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            _slides[index]['description'],
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF555555),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicators() {
    return List.generate(
      _slides.length,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 10,
        width: _currentPage == index ? 25 : 10,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color:
              _currentPage == index
                  ? _slides[_currentPage]['accent']
                  : _slides[_currentPage]['accent'].withOpacity(0.3),
        ),
      ),
    );
  }
}
