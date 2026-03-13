import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unidesk_admin/main.dart';
import 'package:unidesk_admin/core/app_theme.dart';
import 'package:unidesk_admin/widgets/skeleton_loader.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddUserDialog(String initialRole) {
    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (context) => AddUserDialog(initialRole: initialRole),
    );
  }

  Future<void> _deleteUser(String docId, String email) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm Deletion', style: TextStyle(color: Colors.red)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete user $email?'),
                  const SizedBox(height: 16),
                  const Text('Please enter your admin password to confirm.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    obscureText: true,
                    validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: isLoading ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setState(() => isLoading = true);
                  try {
                    final currentAdmin = FirebaseAuth.instance.currentUser;
                    if (currentAdmin != null && currentAdmin.email != null) {
                      AuthCredential credential = EmailAuthProvider.credential(email: currentAdmin.email!, password: passwordController.text);
                      await currentAdmin.reauthenticateWithCredential(credential);
                      await _firestore.collection('users').doc(docId).delete();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully')));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  } finally {
                    if (context.mounted) setState(() => isLoading = false);
                  }
                },
                child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Delete User'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> data, String userId) {
    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = isDark ? AppTheme.pastelBlue : Theme.of(context).primaryColor;
        final bool isOnline = data['status'] == 'online';

        return AlertDialog(
          title: Row(
            children: [
              Icon(data['role'] == 'student' ? Icons.school : Icons.admin_panel_settings, color: primaryColor),
              const SizedBox(width: 8),
              const Text('User Details'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(data['name']?.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(data['name'] ?? 'Unknown Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(data['email'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: isOnline ? Colors.green : Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(isOnline ? 'Online' : 'Offline', style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Role', data['role']?.toUpperCase() ?? 'UNKNOWN'),
              if (data['role'] == 'student') ...[
                _buildDetailRow('Student ID', data['studentId'] ?? 'Not assigned'),
                _buildDetailRow('Course', data['degree'] ?? 'Not specified'),
                _buildDetailRow('Batch', data['batch'] ?? 'Not specified'),
              ],
              if (data['createdAt'] != null)
                _buildDetailRow('Created', DateFormat('MMM d, yyyy').format((data['createdAt'] as Timestamp).toDate())),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                UniDeskAdminApp.showAppDialog(
                  context: context,
                  builder: (context) => EditUserDialog(userData: data, userId: userId),
                );
              },
              child: Text('Edit', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const Center(child: Text('No users found.'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.pastelBlue : Theme.of(context).primaryColor;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showUserDetails(data, doc.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  data['role'] == 'student' ? 'S' : 'A',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(data['name'] ?? 'Unknown Name', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                data['role'] == 'student'
                    ? '${data['studentId'] ?? 'No ID'} • ${data['email']}'
                    : '${data['email']} • Role: ${data['role']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteUser(doc.id, data['email'] ?? 'Unknown User'),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.pastelBlue : Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              _buildAddUserButton(isDark, primaryColor),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [Tab(text: 'Admins'), Tab(text: 'Students')],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const TableSkeleton();
                final allDocs = snapshot.data!.docs;
                final adminDocs = allDocs.where((doc) => (doc.data() as Map)['role'] != 'student').toList();
                final studentDocs = allDocs.where((doc) => (doc.data() as Map)['role'] == 'student').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [_buildUserList(adminDocs), _buildUserList(studentDocs)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddUserButton(bool isDark, Color primaryColor) {
    return PopupMenuButton<String>(
      tooltip: 'Add User',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: isDark ? Colors.black : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Add User', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'admin', child: Text('Lecturer (Admin)')),
        const PopupMenuItem(value: 'student', child: Text('Student')),
      ],
      onSelected: _showAddUserDialog,
    );
  }
}

class AddUserDialog extends StatefulWidget {
  final String initialRole;
  const AddUserDialog({super.key, required this.initialRole});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  late String _role;
  bool _isLoading = false;
  String? _selectedDegree = 'BA (Hons) Creative Multimedia (CM)';
  String? _selectedBatch = '24.1';

  final List<String> _degreePrograms = [
    'BSc (Hons) Computing (COMP)', 'BSc (Hons) Software Engineering (SE)', 'BA (Hons) Creative Multimedia (CM)', 'BA (Hons) Human Resource Management (HRM)', 'BSc (Hons) Business Management (BM)'
  ];

  final List<String> _batches = ['22.1', '22.2', '23.1', '23.2', '24.1', '24.2', '25.1'];

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    if (_role == 'student') _generateStudentId();
  }

  void _generateStudentId() {
    final randomPart = (DateTime.now().millisecondsSinceEpoch % 100).toString().padLeft(2, '0');
    _studentIdController.text = 'STU-$_selectedBatch-$randomPart';
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(name: 'SecondaryApp', options: Firebase.app().options);
      final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await secondaryApp.delete();

      if (userCredential.user != null) {
        final Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'offline',
        };
        if (_role == 'student') {
          userData['degree'] = _selectedDegree;
          userData['batch'] = _selectedBatch;
          userData['studentId'] = _studentIdController.text.trim();
        }
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New ${_role == 'admin' ? 'Lecturer' : 'Student'}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v!.length < 6 ? 'Too short' : null),
              if (_role == 'student') ...[
                TextFormField(controller: _studentIdController, decoration: const InputDecoration(labelText: 'Student ID')),
                DropdownButtonFormField<String>(value: _selectedDegree, items: _degreePrograms.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _selectedDegree = v)),
                DropdownButtonFormField<String>(value: _selectedBatch, items: _batches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (v) => setState(() => _selectedBatch = v)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _isLoading ? null : _createUser, child: const Text('Create User')),
      ],
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;
  const EditUserDialog({super.key, required this.userData, required this.userId});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            setState(() => _isLoading = true);
            await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'name': _nameController.text});
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
