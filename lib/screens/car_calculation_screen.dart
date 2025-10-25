import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarCalculationScreen extends StatefulWidget {
  const CarCalculationScreen({super.key});

  @override
  State<CarCalculationScreen> createState() => _CarCalculationScreenState();
}

class _CarCalculationScreenState extends State<CarCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isCalculating = false;

  String? selectedCarType;
  final List<String> carTypes = ['Tesla', 'Nissan', 'KIA', 'Other'];

  final TextEditingController batteryCapacityController = TextEditingController();
  final TextEditingController actualMileageController = TextEditingController();
  final TextEditingController kmToCalculateController = TextEditingController();

  double? resultCost;
  final double pricePerKwh = 0.2;

  Future<void> calculateCost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isCalculating = true);

      final double batteryCapacity = double.parse(batteryCapacityController.text);
      final double kmDriven = double.parse(actualMileageController.text);
      final double kmToCalculate = double.parse(kmToCalculateController.text);

      double energyPerKm = batteryCapacity / kmDriven;
      double cost = energyPerKm * pricePerKwh * kmToCalculate;

      // ✅ حفظ النتيجة في Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calc')
            .add({
          'car_type': selectedCarType ?? "غير محدد",
          'battery_capacity': batteryCapacity,
          'mileage': kmDriven,
          'km_to_calculate': kmToCalculate,
          'result_cost': cost,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          resultCost = cost;
          _isCalculating = false;
        });
      });
    }
  }

  @override
  void dispose() {
    batteryCapacityController.dispose();
    actualMileageController.dispose();
    kmToCalculateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب تكلفة شحن السيارة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.ev_station, size: 90, color: Colors.teal),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'نوع السيارة'),
                value: selectedCarType,
                items: carTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCarType = val),
                validator: (val) => val == null ? 'يرجى اختيار نوع السيارة' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: batteryCapacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'حجم البطارية (كيلو واط)'),
                validator: (val) => val!.isEmpty ? 'أدخل قيمة صحيحة' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: actualMileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الممشى الفعلي (كم)'),
                validator: (val) => val!.isEmpty ? 'أدخل قيمة صحيحة' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: kmToCalculateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'عدد الكيلومترات للحساب'),
                validator: (val) => val!.isEmpty ? 'أدخل قيمة صحيحة' : null,
              ),
              const SizedBox(height: 25),
              _isCalculating
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : ElevatedButton(
                onPressed: calculateCost,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('احسب التكلفة', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 25),
              if (resultCost != null)
                Text(
                  'التكلفة: ${resultCost!.toStringAsFixed(2)} د.أ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
