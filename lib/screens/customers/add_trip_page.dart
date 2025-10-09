import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTripPage extends StatefulWidget {
  final String customerId;

  const AddTripPage({Key? key, required this.customerId}) : super(key: key);

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPaid = false;
  bool _isSaving = false;

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final customerRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('customers')
          .doc(widget.customerId);

      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

      // إضافة الرحلة
      await customerRef.collection('trips').add({
        'amount': amount,
        'description': _descController.text.trim().isEmpty
            ? 'رحلة بدون وصف'
            : _descController.text.trim(),
        'isPaid': _isPaid,
        'date': DateTime.now(),
      });

      // تحديث المجموع الكلي إن لم تكن مدفوعة
      if (!_isPaid) {
        await _firestore.runTransaction((tx) async {
          final doc = await tx.get(customerRef);
          if (doc.exists) {
            final current = (doc['totalDebt'] ?? 0.0).toDouble();
            tx.update(customerRef, {'totalDebt': current + amount});
          }
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تمت إضافة الرحلة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ أثناء الإضافة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة رحلة جديدة'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ (د.أ)',
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'الرجاء إدخال المبلغ' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'وصف الرحلة',
                  prefixIcon: const Icon(Icons.description, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: _isPaid,
                onChanged: (val) => setState(() => _isPaid = val),
                title: const Text('تم الدفع'),
                activeColor: Colors.teal,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveTrip,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ الرحلة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
