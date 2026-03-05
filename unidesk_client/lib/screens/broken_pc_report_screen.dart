import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BrokenPcReportScreen extends StatefulWidget {
  final String? ticketId;
  final Map<String, dynamic>? existingData;

  const BrokenPcReportScreen({super.key, this.ticketId, this.existingData});

  @override
  State<BrokenPcReportScreen> createState() => _BrokenPcReportScreenState();
}

class _BrokenPcReportScreenState extends State<BrokenPcReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labController = TextEditingController();
  final _pcController = TextEditingController();
  final _issueController = TextEditingController();
  String _issueSeverity = 'Medium (Affects work)';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final details =
          widget.existingData!['details'] as Map<String, dynamic>? ?? {};
      _labController.text = details['Lab Number'] ?? '';
      _pcController.text = details['PC Number/ID'] ?? '';
      _issueSeverity = details['Severity'] ?? 'Medium (Affects work)';
      _issueController.text = details['Issue Description'] ?? '';
    }
  }

  @override
  void dispose() {
    _labController.dispose();
    _pcController.dispose();
    _issueController.dispose();
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
        'serviceType': 'broken_pc_report',
        'serviceTitle': 'Report Broken PC',
        'status': 'Pending',
        'details': {
          'Lab Number': _labController.text.trim(),
          'PC Number/ID': _pcController.text.trim(),
          'Severity': _issueSeverity,
          'Issue Description': _issueController.text.trim(),
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
        title: const Text('Report Broken PC'),
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
                'Incident Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _labController,
                      decoration: const InputDecoration(
                        labelText: 'Lab Number',
                        prefixIcon: Icon(Icons.room),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pcController,
                      decoration: const InputDecoration(
                        labelText: 'PC Number',
                        prefixIcon: Icon(Icons.computer),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _issueSeverity,
                decoration: const InputDecoration(labelText: 'Issue Severity'),
                items: const [
                  DropdownMenuItem(
                    value: 'Low (Minor issue)',
                    child: Text('Low (Minor issue)'),
                  ),
                  DropdownMenuItem(
                    value: 'Medium (Affects work)',
                    child: Text('Medium (Affects work)'),
                  ),
                  DropdownMenuItem(
                    value: 'High (Completely unusable)',
                    child: Text('High (Completely unusable)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _issueSeverity = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _issueController,
                decoration: const InputDecoration(
                  labelText:
                      'Describe the issue (e.g. Blue screen, missing mouse)',
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
