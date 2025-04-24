import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'news_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NewsPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Lottie.asset(
                  'assets/Animation - 1745434641609.json',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    print('Lottie animation loaded successfully: assets/news_animation.json');
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Lottie error: $error');
                    print('Stack trace: $stackTrace');
                    return Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Failed to load animation: $error',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Uncomment the below Image.asset to test if assets are loading correctly
              /*
              FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/news_icon.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Image error: $error');
                    return const Text('Failed to load image');
                  },
                ),
              ),
              */
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Welcome to News App',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Stay updated with the latest news',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}