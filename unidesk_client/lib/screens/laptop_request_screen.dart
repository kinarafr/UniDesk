import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_pickers.dart';

class LaptopRequestScreen extends StatefulWidget {
  final String? ticketId;
  final Map<String, dynamic>? existingData;

  const LaptopRequestScreen({super.key, this.ticketId, this.existingData});

  @override
  State<LaptopRequestScreen> createState() => _LaptopRequestScreenState();
}

class _LaptopRequestScreenState extends State<LaptopRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _reasonController = TextEditingController();
  String _laptopType = 'Normal (Documents & Web)';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final details =
          widget.existingData!['details'] as Map<String, dynamic>? ?? {};
      _laptopType = details['Laptop Type'] ?? 'Normal (Documents & Web)';
      _dateController.text = details['Needed Date'] ?? '';
      _timeController.text = details['Needed Time'] ?? '';
      _durationController.text = details['Duration (Days)'] ?? '';
      _reasonController.text = details['Reason'] ?? '';
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
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
        'serviceType': 'laptop_request',
        'serviceTitle': 'Request Laptop',
        'status': 'Pending',
        'details': {
          'Laptop Type': _laptopType,
          'Needed Date': _dateController.text.trim(),
          'Needed Time': _timeController.text.trim(),
          'Duration (Days)': _durationController.text.trim(),
          'Reason': _reasonController.text.trim(),
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
                  ? 'Request updated successfully!'
                  : 'Laptop request submitted!',
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
      appBar: AppBar(
        title: const Text('Request Laptop'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Laptop Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _laptopType,
                decoration: const InputDecoration(labelText: 'Type of Laptop'),
                items: const [
                  DropdownMenuItem(
                    value: 'Normal (Documents & Web)',
                    child: Text('Normal (Documents & Web)'),
                  ),
                  DropdownMenuItem(
                    value: 'Powerful (3D & Heavy Tasks)',
                    child: Text('Powerful (3D & Heavy Tasks)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _laptopType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => AppPickers.showAppDatePicker(
                        context: context,
                        controller: _dateController,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'When needed? (Date)',
                        hintText: 'Select Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () => AppPickers.showTimePicker(
                        context: context,
                        controller: _timeController,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'What time?',
                        hintText: 'Select Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (Days)',
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for borrowing',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Please explain why you need it' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
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
                            ? 'Update Request'
                            : 'Submit Request',
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
