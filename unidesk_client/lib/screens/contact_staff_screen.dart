import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactStaffScreen extends StatefulWidget {
  final String? ticketId;
  final Map<String, dynamic>? existingData;

  const ContactStaffScreen({super.key, this.ticketId, this.existingData});

  @override
  State<ContactStaffScreen> createState() => _ContactStaffScreenState();
}

class _ContactStaffScreenState extends State<ContactStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _department = 'General IT Support';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final details =
          widget.existingData!['details'] as Map<String, dynamic>? ?? {};
      _department = details['Department'] ?? 'General IT Support';
      if (_department == 'Finance / Fees')
        _department =
            'Finance / Fees'; // Ensure valid enum equivalent matching (just string matching here)
      _subjectController.text = details['Subject'] ?? '';
      _messageController.text = details['Message'] ?? '';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';

      final ticketData = {
        'userId': user.uid,
        'userName': userName,
        'userEmail': user.email,
        'serviceType': 'contact_staff',
        'serviceTitle': 'Contact Staff',
        'status': 'Pending',
        'details': {
          'Department': _department,
          'Subject': _subjectController.text.trim(),
          'Message': _messageController.text.trim(),
        },
      };

      if (widget.ticketId != null) {
        await FirebaseFirestore.instance
            .collection('tickets')
            .doc(widget.ticketId)
            .update(ticketData);
      } else {
        ticketData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('tickets').add(ticketData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ticketId != null
                  ? 'Message updated!'
                  : 'Message sent to staff!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Staff')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Send Message',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _department,
                decoration: const InputDecoration(labelText: 'Department'),
                items: const [
                  DropdownMenuItem(
                    value: 'General IT Support',
                    child: Text('General IT Support'),
                  ),
                  DropdownMenuItem(
                    value: 'Finance / Fees',
                    child: Text('Finance / Fees'),
                  ),
                  DropdownMenuItem(
                    value: 'Student Affairs',
                    child: Text('Student Affairs'),
                  ),
                  DropdownMenuItem(
                    value: 'Library Admin',
                    child: Text('Library Admin'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _department = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.short_text),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a message' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMessage,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.ticketId != null
                            ? 'Update Message'
                            : 'Send Message',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
