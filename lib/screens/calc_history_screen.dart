import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CalcHistoryPage extends StatelessWidget {
  const CalcHistoryPage({super.key});

  Color _getCostColor(double cost) {
    if (cost <= 5) return Colors.green;
    if (cost <= 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("يرجى تسجيل الدخول")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("سجل حسابات السيارة"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calc')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "لا يوجد عمليات حساب بعد",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final calcList = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: calcList.length,
            itemBuilder: (context, index) {
              final data = calcList[index].data() as Map<String, dynamic>;
              final id = calcList[index].id;
              final cost = (data['result_cost'] ?? 0).toDouble();
              final costColor = _getCostColor(cost);

              return Dismissible(
                key: Key(id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('calc')
                      .doc(id)
                      .delete();
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // ✅ أيقونة السيارة دائرية
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(Icons.directions_car, color: Colors.teal, size: 30),
                        ),
                        const SizedBox(width: 16),

                        // ✅ بيانات
                        Expanded(
                          child: Text(
                            "المسافة: ${data['km_to_calculate']} كم",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // ✅ Badge التكلفة
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: costColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: costColor, width: 1.5),
                          ),
                          child: Text(
                            "${cost.toStringAsFixed(2)} د.أ",
                            style: TextStyle(
                              color: costColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
