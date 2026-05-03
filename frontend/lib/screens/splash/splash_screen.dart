import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Safety net: if checkAuthStatus hangs, force unauthenticated after 5s
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.status == AuthStatus.unknown) {
        auth.forceUnauthenticated();
      }
    });

    try {
      await context
          .read<AuthProvider>()
          .checkAuthStatus()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // API not reachable, proceed to login
      if (!mounted) return;
      context.read<AuthProvider>().forceUnauthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'PAW',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adopción de Mascotas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
