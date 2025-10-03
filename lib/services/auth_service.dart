import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تسجيل الدخول بالبريد وكلمة المرور
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // إنشاء حساب جديد + (تخزين بيانات إضافية إذا موجودة)
  Future<UserCredential> signUpWithEmail(
      String email,
      String password, [
        Map<String, dynamic>? extraData,
      ]) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // إذا في بيانات إضافية نخزنها في Firestore
    if (extraData != null) {
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "email": email,
        ...extraData,
      });
    } else {
      // إذا ما في بيانات إضافية نحفظ البريد فقط
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "email": email,
      });
    }

    return userCredential;
  }

  // جلب بيانات المستخدم من Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserData(String uid, Map<String, dynamic> newData) async {
    await _firestore.collection("users").doc(uid).update(newData);
  }

  // حذف بيانات المستخدم (Firestore + Auth)
  Future<void> deleteUserData(String uid) async {
    await _firestore.collection("users").doc(uid).delete();
    await _auth.currentUser?.delete();
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;
}
