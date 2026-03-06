import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MissingItemReportScreen extends StatefulWidget {
  final String? ticketId;
  final Map<String, dynamic>? existingData;

  const MissingItemReportScreen({super.key, this.ticketId, this.existingData});

  @override
  State<MissingItemReportScreen> createState() =>
      _MissingItemReportScreenState();
}

class _MissingItemReportScreenState extends State<MissingItemReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final details =
          widget.existingData!['details'] as Map<String, dynamic>? ?? {};
      _itemController.text = details['Item Name'] ?? '';
      _locationController.text = details['Last Seen Location'] ?? '';
      _timeController.text = details['Time Last Seen'] ?? '';
      _descriptionController.text = details['Description/Color/Brand'] ?? '';
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
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
        'serviceType': 'missing_item_report',
        'serviceTitle': 'Report Missing Item',
        'status': 'Pending',
        'details': {
          'Item Name': _itemController.text.trim(),
          'Last Seen Location': _locationController.text.trim(),
          'Time Last Seen': _timeController.text.trim(),
          'Description/Color/Brand': _descriptionController.text.trim(),
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
                  ? 'Report updated successfully!'
                  : 'Report submitted successfully!',
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
        title: const Text('Report Missing Item'),
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
                'Item Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. Blue Water Bottle',
                  prefixIcon: Icon(Icons.backpack),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Last Seen Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time Last Seen',
                        hintText: 'e.g. 2:00 PM today',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Detailed Description (Color, Brand, Marks)',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
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
                            ? 'Update Report'
                            : 'Submit Report',
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
