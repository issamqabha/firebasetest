import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../calc_history_screen.dart';
import '../car_calculation_screen.dart';
import '../customers/add_customer_page.dart';
import '../customers/customer_details_page.dart';
import '../profile/profile_info.dart';
import '../auth/auth_gate.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _driverData;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() => _driverData = doc.data());
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) {
      return const Scaffold(
        body: Center(child: Text('جاري تحميل المستخدم...')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر ديون التاكسي'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverData,
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                _driverData?['name'] ?? 'السائق',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                _driverData?['email'] ?? _auth.currentUser?.email ?? '',
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.teal),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("الملف الشخصي"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileInfo()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.ev_station, color: Colors.teal),
              title: const Text("حساب تكلفة السيارة"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CarCalculationScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.teal),
              title: const Text("سجل حسابات السيارة"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalcHistoryPage()),
                );
              },
            ),


            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("تسجيل الخروج"),
              onTap: _signOut,
            ),
          ],
        ),
      ),

      backgroundColor: Colors.grey[100],

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(driverId)
            .collection('customers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد زبائن بعد.\nأضف أول زبون من الزر بالأسفل 👇',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final customers = snapshot.data!.docs;
          double totalDebtAll = 0;
          for (var doc in customers) {
            totalDebtAll += (doc['totalDebt'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // ✅ شريط المجموع + زر السيارة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'إجمالي الديون لجميع الزبائن',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${totalDebtAll.toStringAsFixed(2)} د.أ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ✅ زر أيقونة السيارة داخل الهوم بيج
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CarCalculationScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.directions_car, color: Colors.teal, size: 28),
                            SizedBox(width: 10),
                            Text(
                              "حساب تكلفة السيارة",
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🧾 قائمة الزبائن
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final data = customers[index].data() as Map<String, dynamic>;
                    final id = customers[index].id;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          data['name'] ?? 'بدون اسم',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text('الهاتف: ${data['phone'] ?? 'غير محدد'}'),
                        trailing: Text(
                          '${data['totalDebt'] ?? 0} د.أ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailsPage(
                                customerId: id,
                                name: data['name'] ?? 'زبون',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
        },
        label: const Text('إضافة زبون'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
