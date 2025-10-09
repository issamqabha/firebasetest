// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'sign_in_page.dart';
// import '../home/home_page.dart';
//
// class SignUpPage extends StatefulWidget {
//   const SignUpPage({Key? key}) : super(key: key);
//
//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _specialtyController = TextEditingController();
//
//   String _selectedGender = "Male"; // القيمة الافتراضية
//   bool _passwordVisible = false;
//   bool _isSigningUp = false;
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _nameController.dispose();
//     _ageController.dispose();
//     _specialtyController.dispose();
//     super.dispose();
//   }
//
//   String? _validateEmail(String? value) {
//     if (value == null || value.isEmpty) return 'Enter your email';
//     final emailRegex = RegExp(
//       r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
//     );
//     if (!emailRegex.hasMatch(value)) return 'Enter a valid email format';
//     return null;
//   }
//
//   String? _validatePassword(String? value) {
//     if (value == null || value.isEmpty) return 'Enter your password';
//     if (value.length < 6) return 'Password must be at least 6 characters';
//     return null;
//   }
//
//   String? _validateRequired(String? value) {
//     if (value == null || value.isEmpty) return 'This field is required';
//     return null;
//   }
//
//   Future<void> _signUp() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isSigningUp = true);
//
//     try {
//       final userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//
//       final user = userCredential.user;
//
//       if (user != null) {
//         // ✅ تخزين بيانات إضافية في Firestore
//         await _firestore.collection("users").doc(user.uid).set({
//           "email": _emailController.text.trim(),
//           "name": _nameController.text.trim(),
//           "age": _ageController.text.trim(),
//           "gender": _selectedGender,
//           "specialty": _specialtyController.text.trim(),
//           "createdAt": DateTime.now(),
//         });
//
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const HomePage()),
//           );
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       String message;
//       if (e.code == 'email-already-in-use') {
//         message = 'This email is already in use';
//       } else if (e.code == 'weak-password') {
//         message = 'The password is too weak';
//       } else {
//         message = 'Error: ${e.message}';
//       }
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(message), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSigningUp = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Card(
//             elevation: 10,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.app_registration,
//                         size: 60, color: Colors.teal),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Sign Up',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.teal.shade700,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // الاسم
//                     TextFormField(
//                       controller: _nameController,
//                       decoration: InputDecoration(
//                         labelText: 'Name',
//                         prefixIcon: const Icon(Icons.person),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator: _validateRequired,
//                     ),
//                     const SizedBox(height: 16),
//
//                     // العمر
//                     TextFormField(
//                       controller: _ageController,
//                       keyboardType: TextInputType.number,
//                       decoration: InputDecoration(
//                         labelText: 'Age',
//                         prefixIcon: const Icon(Icons.calendar_today),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator: _validateRequired,
//                     ),
//                     const SizedBox(height: 16),
//
//                     // الجنس
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       items: const [
//                         DropdownMenuItem(
//                             value: "Male", child: Text("Male")),
//                         DropdownMenuItem(
//                             value: "Female", child: Text("Female")),
//                       ],
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedGender = value!;
//                         });
//                       },
//                       decoration: InputDecoration(
//                         labelText: 'Gender',
//                         prefixIcon: const Icon(Icons.people),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // التخصص
//                     TextFormField(
//                       controller: _specialtyController,
//                       decoration: InputDecoration(
//                         labelText: 'Specialty',
//                         prefixIcon: const Icon(Icons.work),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator: _validateRequired,
//                     ),
//                     const SizedBox(height: 16),
//
//                     // الإيميل
//                     TextFormField(
//                       controller: _emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         prefixIcon: const Icon(Icons.email),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator: _validateEmail,
//                     ),
//                     const SizedBox(height: 16),
//
//                     // الباسورد
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: !_passwordVisible,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         prefixIcon: const Icon(Icons.lock),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _passwordVisible
//                                 ? Icons.visibility
//                                 : Icons.visibility_off,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _passwordVisible = !_passwordVisible;
//                             });
//                           },
//                         ),
//                       ),
//                       validator: _validatePassword,
//                     ),
//                     const SizedBox(height: 20),
//
//                     // زر التسجيل
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.teal,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: _isSigningUp ? null : _signUp,
//                         child: _isSigningUp
//                             ? const CircularProgressIndicator(
//                           color: Colors.white,
//                         )
//                             : const Text(
//                           'Sign Up',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // زر للانتقال إلى تسجيل الدخول
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(builder: (_) => SignInPage()),
//                         );
//                       },
//                       child: const Text("Already have an account? Sign In"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
