import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ProfileInfo extends StatefulWidget {
  const ProfileInfo({Key? key}) : super(key: key);

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late DateFormat _dateFormat;
  late DateFormat _timeFormat;

  @override
  void initState() {
    super.initState();
    _initializeFormats();
  }

  Future<void> _initializeFormats() async {
    await initializeDateFormatting('ar_SA', null);
    _dateFormat = DateFormat.yMMMMd('ar_SA');
    _timeFormat = DateFormat.Hm('ar_SA');
  }

  // تعديل فيلد
  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تعديل $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "أدخل $field الجديد"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = firebaseAuth.currentUser;
              if (user != null) {
                await firestore.collection("users").doc(user.uid).update({
                  field: controller.text.trim(),
                });
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  // حذف فيلد
  Future<void> _deleteField(String field) async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      await firestore.collection("users").doc(user.uid).update({
        field: FieldValue.delete(),
      });
      setState(() {});
    }
  }

  // حذف الحساب (الوثيقة كاملة)
  Future<void> _deleteDocument() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      await firestore.collection("users").doc(user.uid).delete();
      await user.delete(); // حذف المستخدم من FirebaseAuth كمان
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = firebaseAuth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "معلومات البروفايل",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection("users").doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("لا توجد بيانات للمستخدم"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade700, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 60, color: Colors.teal.shade700),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        data["email"] ?? user?.email ?? "No Email",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // معلومات أساسية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildModernCard(
                        icon: Icons.person,
                        title: "المعلومات الشخصية",
                        children: [
                          _buildInfoItem(
                            icon: Icons.person_outline,
                            label: "الاسم",
                            value: data["name"] ?? "غير متوفر",
                            onEdit: () =>
                                _editField("name", data["name"] ?? ""),
                            onDelete: () => _deleteField("name"),
                          ),
                          const Divider(),
                          _buildInfoItem(
                            icon: Icons.cake,
                            label: "العمر",
                            value: data["age"] ?? "غير متوفر",
                            onEdit: () =>
                                _editField("age", data["age"] ?? ""),
                            onDelete: () => _deleteField("age"),
                          ),
                          const Divider(),
                          _buildInfoItem(
                            icon: Icons.people,
                            label: "الجنس",
                            value: data["gender"] ?? "غير متوفر",
                            onEdit: () =>
                                _editField("gender", data["gender"] ?? ""),
                            onDelete: () => _deleteField("gender"),
                          ),
                          const Divider(),
                          _buildInfoItem(
                            icon: Icons.work,
                            label: "التخصص",
                            value: data["specialty"] ?? "غير متوفر",
                            onEdit: () =>
                                _editField("specialty", data["specialty"] ?? ""),
                            onDelete: () => _deleteField("specialty"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildModernCard(
                        icon: Icons.email_outlined,
                        title: "معلومات الاتصال",
                        children: [
                          _buildInfoItem(
                            icon: Icons.alternate_email_outlined,
                            label: "البريد الإلكتروني",
                            value: data["email"] ?? user?.email ?? "غير متوفر",
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await _deleteDocument();
                          if (mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_forever, color: Colors.white),
                        label: const Text(
                          "حذف الحساب بالكامل",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // بناء الكارت
  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Column(children: children),
          ],
        ),
      ),
    );
  }

  // عنصر المعلومات
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.teal),
            onPressed: onEdit,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
      ],
    );
  }
}
