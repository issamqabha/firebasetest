import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_trip_page.dart';

class CustomerDetailsPage extends StatefulWidget {
  final String customerId;
  final String name;

  const CustomerDetailsPage({
    Key? key,
    required this.customerId,
    required this.name,
  }) : super(key: key);

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _editCustomer(Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل بيانات الزبون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = _auth.currentUser!.uid;
              await _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('customers')
                  .doc(widget.customerId)
                  .update({
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
              });
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تم تحديث بيانات الزبون')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _addOldDebt() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دين قديم 💰'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'المبلغ (د.أ)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'وصف الدين'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = _auth.currentUser!.uid;
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ أدخل مبلغ صالح')),
                );
                return;
              }

              await _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('customers')
                  .doc(widget.customerId)
                  .collection('trips')
                  .add({
                'description': descController.text.isEmpty
                    ? 'دين قديم'
                    : descController.text.trim(),
                'amount': amount,
                'isPaid': false,
                'date': DateTime.now(),
              });

              final customerRef = _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('customers')
                  .doc(widget.customerId);

              await _firestore.runTransaction((tx) async {
                final snap = await tx.get(customerRef);
                final total = (snap['totalDebt'] ?? 0.0) + amount;
                tx.update(customerRef, {'totalDebt': total});
              });

              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تمت إضافة الدين')),
              );
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTrip(String tripId, double amount, bool isPaid) async {
    final uid = _auth.currentUser!.uid;
    final tripRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('customers')
        .doc(widget.customerId)
        .collection('trips')
        .doc(tripId);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذه الرحلة أو الدين القديم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await tripRef.delete();

    // تحديث المجموع فقط إذا لم تكن الرحلة مدفوعة
    if (!isPaid) {
      final customerRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('customers')
          .doc(widget.customerId);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(customerRef);
        final total = (snap['totalDebt'] ?? 0.0) - amount;
        tx.update(customerRef, {'totalDebt': total < 0 ? 0.0 : total});
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ تم حذف الرحلة بنجاح')),
    );
  }

  Future<void> _deleteCustomer() async {
    final uid = _auth.currentUser!.uid;
    final customerRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('customers')
        .doc(widget.customerId);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد حذف الزبون'),
        content: const Text('هل تريد حذف الزبون وجميع الرحلات الخاصة به؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final tripsSnap = await customerRef.collection('trips').get();
    for (var doc in tripsSnap.docs) {
      await doc.reference.delete();
    }
    await customerRef.delete();

    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ تم حذف الزبون بالكامل')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    final customerRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('customers')
        .doc(widget.customerId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('الزبون: ${widget.name}'),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
        stream: customerRef.snapshots(),
        builder: (context, customerSnapshot) {
          if (!customerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final customerData =
              customerSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          return StreamBuilder<QuerySnapshot>(
            stream: customerRef
                .collection('trips')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, tripSnapshot) {
              if (tripSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final trips = tripSnapshot.data?.docs ?? [];
              double totalDebt = 0;
              for (var trip in trips) {
                final data = trip.data() as Map<String, dynamic>;
                if (data['isPaid'] == false) {
                  totalDebt += (data['amount'] ?? 0).toDouble();
                }
              }

              return Column(
                children: [
                  // 🟢 الهيدر (المجموع)
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                          'المجموع الحالي:',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          '${totalDebt.toStringAsFixed(2)} د.أ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final data = trips[index].data() as Map<String, dynamic>;
                        final isPaid = data['isPaid'] ?? false;
                        final amount = (data['amount'] ?? 0.0).toDouble();
                        final tripId = trips[index].id;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isPaid
                                  ? Icons.check_circle
                                  : Icons.pending_actions,
                              color: isPaid ? Colors.green : Colors.orange,
                            ),
                            title: Text(data['description'] ?? 'بدون وصف'),
                            subtitle: Text(
                              'المبلغ: ${amount.toStringAsFixed(2)} د.أ\n${data['date'].toDate()}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteTrip(tripId, amount, isPaid),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'edit',
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.edit),
            label: const Text('تعديل الزبون'),
            onPressed: () async {
              final uid = _auth.currentUser!.uid;
              final doc = await _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('customers')
                  .doc(widget.customerId)
                  .get();
              if (doc.exists) {
                _editCustomer(doc.data() as Map<String, dynamic>);
              }
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'oldDebt',
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.attach_money),
            label: const Text('إضافة دين قديم'),
            onPressed: _addOldDebt,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'trip',
            backgroundColor: Colors.teal,
            icon: const Icon(Icons.add),
            label: const Text('إضافة رحلة'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTripPage(customerId: widget.customerId),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'delete',
            backgroundColor: Colors.red,
            icon: const Icon(Icons.delete_forever),
            label: const Text('حذف الزبون'),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
    );
  }
}
