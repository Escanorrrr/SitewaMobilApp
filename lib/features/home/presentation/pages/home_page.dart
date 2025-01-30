import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: authState.maybeWhen(
          authenticated: (user) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hoş geldiniz, ${user.name}!'),
              const SizedBox(height: 16),
              Text('E-posta: ${user.email}'),
            ],
          ),
          orElse: () => const CircularProgressIndicator(),
        ),
      ),
    );
  }
} 