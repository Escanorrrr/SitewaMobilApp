import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/login_request.dart';
import '../providers/auth_notifier.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _siteCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _siteCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final request = LoginRequest(
        siteCode: _siteCodeController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      ref.read(authNotifierProvider.notifier).login(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
        orElse: () {},
      );
    });

    final state = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hoş Geldiniz',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                TextFormField(
                  controller: _siteCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Site Kodu',
                    hintText: 'Örn: BLOK2',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Site kodu boş olamaz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    hintText: 'Kullanıcı adınızı girin',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kullanıcı adı boş olamaz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    hintText: 'Şifrenizi girin',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre boş olamaz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: state.maybeWhen(
                    loading: () => null,
                    orElse: () => _handleLogin,
                  ),
                  child: state.maybeWhen(
                    loading: () => const CircularProgressIndicator(),
                    orElse: () => const Text('Giriş Yap'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 