import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../home/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isLoading = false;
  bool passwordVisible = false;

  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _specialtyController = TextEditingController();
  String _selectedGender = "Male";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;
        if (user != null) {
          await _firestore.collection("users").doc(user.uid).set({
            "email": _emailController.text.trim(),
            "name": _nameController.text.trim(),
            "age": _ageController.text.trim(),
            "gender": _selectedGender,
            "specialty": _specialtyController.text.trim(),
            "createdAt": DateTime.now(),
          });
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "حدث خطأ أثناء تسجيل الدخول"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ====== Google Sign-In (يدعم الويب والموبايل) ======
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 🟢 للويب
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        final userCredential =
        await FirebaseAuth.instance.signInWithPopup(authProvider);
        await _saveUserToFirestore(userCredential.user);
        return userCredential;
      } else {
        // 📱 للموبايل
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _saveUserToFirestore(userCredential.user);
        return userCredential;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول عبر Google: $e')),
      );
      return null;
    }
  }

  // ====== Facebook Sign-In ======
  Future<UserCredential?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // 🟢 للويب
        final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        final userCredential =
        await FirebaseAuth.instance.signInWithPopup(facebookProvider);
        await _saveUserToFirestore(userCredential.user);
        return userCredential;
      } else {
        // 📱 للموبايل
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final credential =
          FacebookAuthProvider.credential(result.accessToken!.token);

          final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _saveUserToFirestore(userCredential.user);
          return userCredential;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء تسجيل الدخول عبر Facebook')),
          );
          return null;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول عبر Facebook: $e')),
      );
      return null;
    }
  }

  // 🧠 دالة لحفظ المستخدم في Firestore بعد أول تسجيل
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;
    final doc = await _firestore.collection("users").doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection("users").doc(user.uid).set({
        "email": user.email,
        "name": user.displayName ?? "",
        "age": "",
        "gender": "",
        "specialty": "",
        "createdAt": DateTime.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isLogin ? Icons.login : Icons.person_add,
                        size: 60, color: Colors.teal),
                    const SizedBox(height: 10),
                    Text(
                      isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== الحقول الإضافية عند التسجيل فقط =====
                    if (!isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل اسمك' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'العمر',
                          prefixIcon: Icon(Icons.cake),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل عمرك' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'الجنس',
                          prefixIcon: Icon(Icons.people),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('ذكر')),
                          DropdownMenuItem(value: 'Female', child: Text('أنثى')),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _specialtyController,
                        decoration: const InputDecoration(
                          labelText: 'التخصص',
                          prefixIcon: Icon(Icons.work),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'أدخل تخصصك أو مهنتك'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // الإيميل
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'أدخل بريدك الإلكتروني'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // الباسورد
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => passwordVisible = !passwordVisible),
                        ),
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty ? 'أدخل كلمة المرور' : null,
                    ),
                    const SizedBox(height: 20),

                    // زر الدخول / التسجيل
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _authenticate,
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== تسجيل الدخول الاجتماعي =====
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: Image.asset('assets/google.png', height: 24),
                          label: const Text("تسجيل الدخول عبر Google"),
                          onPressed: () async {
                            final user = await signInWithGoogle();
                            if (user != null && mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: Image.asset('assets/facebook.png', height: 24),
                          label: const Text("تسجيل الدخول عبر Facebook"),
                          onPressed: () async {
                            final user = await signInWithFacebook();
                            if (user != null && mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // زر التبديل بين الوضعين
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? "ليس لديك حساب؟ أنشئ حسابًا"
                            : "لديك حساب بالفعل؟ تسجيل الدخول",
                        style: const TextStyle(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
