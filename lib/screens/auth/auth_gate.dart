import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'sign_in_page.dart';
import '../home/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _ensureUserDoc(User user) async {
    final docRef =
    FirebaseFirestore.instance.collection("users").doc(user.uid);

    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder(
            future: _ensureUserDoc(user),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return HomePage(); // ✅ بدون const
            },
          );
        }
        return SignInPage(); // ✅ بدون const لأنها StatefulWidget
      },
    );
  }
}
