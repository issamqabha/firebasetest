import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_page.dart';
import 'auth_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final auth = FirebaseAuth.instance;

    try {
      _user = auth.currentUser;

      // متابعة تغير حالة المستخدم
      auth.authStateChanges().listen((user) {
        if (mounted) {
          setState(() {
            _user = user;
            _loading = false;
          });
        }
      });

      // Timeout احتياطي لمنع التجمّد
      await Future.delayed(const Duration(seconds: 5));
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'email': user.email,
        'name': user.displayName ?? '',
        'createdAt': DateTime.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // 🟡 شاشة التحميل الاحترافية
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة رئيسية (يمكنك لاحقًا استبدالها بصورة شعارك)
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.all(30),
                child: const Icon(
                  Icons.local_taxi,
                  size: 80,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'دفتر ديون التاكسي',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'جارٍ التحميل...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.teal,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }

    // 🧑‍💻 المستخدم غير موجود → صفحة تسجيل الدخول
    if (_user == null) {
      return const AuthPage();
    }

    // ✅ المستخدم موجود → التأكد من بياناته في Firestore
    return FutureBuilder(
      future: _ensureUserDoc(_user!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          );
        }
        return const HomePage();
      },
    );
  }
}
