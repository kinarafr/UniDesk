import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_pickers.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String? ticketId;
  final Map<String, dynamic>? existingData;

  const AppointmentBookingScreen({super.key, this.ticketId, this.existingData});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lecturerController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _reasonController = TextEditingController();
  String _appointmentType = 'In-Person';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final details =
          widget.existingData!['details'] as Map<String, dynamic>? ?? {};
      _lecturerController.text = details['Lecturer Name'] ?? '';
      _appointmentType = details['Type'] ?? 'In-Person';
      _dateController.text = details['Preferred Date'] ?? '';
      _timeController.text = details['Preferred Time'] ?? '';
      _reasonController.text = details['Reason'] ?? '';
    }
  }

  @override
  void dispose() {
    _lecturerController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
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
        'serviceType': 'lecturer_appointment',
        'serviceTitle': 'Book Appointment',
        'status': 'Pending',
        'details': {
          'Lecturer Name': _lecturerController.text.trim(),
          'Type': _appointmentType,
          'Preferred Date': _dateController.text.trim(),
          'Preferred Time': _timeController.text.trim(),
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
                  ? 'Appointment updated successfully!'
                  : 'Appointment request submitted successfully!',
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
        title: const Text('Book Appointment'),
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
                'Meeting Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lecturerController,
                decoration: const InputDecoration(
                  labelText: 'Lecturer Name',
                  hintText: 'e.g. Dr. John Doe',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _appointmentType,
                decoration: const InputDecoration(labelText: 'Meeting Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'In-Person',
                    child: Text('In-Person (Office)'),
                  ),
                  DropdownMenuItem(
                    value: 'Online (Zoom/Teams)',
                    child: Text('Online (Zoom/Teams)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _appointmentType = value);
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
                        labelText: 'Preferred Date',
                        prefixIcon: Icon(Icons.calendar_month),
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
                        labelText: 'Preferred Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Appointment (Briefly explain)',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
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
