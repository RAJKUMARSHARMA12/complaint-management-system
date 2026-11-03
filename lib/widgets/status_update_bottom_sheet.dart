import 'package:flutter/material.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/widgets/status_chip.dart';

class StatusUpdateBottomSheet extends StatefulWidget {
  final ComplaintModel complaint;
  final List<String> allowedTransitions;
  final Future<bool> Function(String nextStatus, String remark) onUpdateStatus;

  const StatusUpdateBottomSheet({
    super.key,
    required this.complaint,
    required this.allowedTransitions,
    required this.onUpdateStatus,
  });

  @override
  State<StatusUpdateBottomSheet> createState() => _StatusUpdateBottomSheetState();
}

class _StatusUpdateBottomSheetState extends State<StatusUpdateBottomSheet> {
  final TextEditingController _remarkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedStatus;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.allowedTransitions.isNotEmpty) {
      _selectedStatus = widget.allowedTransitions.first;
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStatus == null) {
      setState(() {
        _errorMessage = 'Please select a valid next status.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onUpdateStatus(
      _selectedStatus!,
      _remarkController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Failed to update status. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Ticket Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    widget.complaint.complaintId,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Current Status: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  StatusChip(status: widget.complaint.status, fontSize: 11),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Next Status (FSM Rules):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.allowedTransitions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No transitions allowed from this status (Terminal State).',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  children: widget.allowedTransitions.map((status) {
                    final isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      key: Key('transition_chip_$status'),
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: Colors.indigo.shade100,
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.indigo.shade900 : Colors.black87,
                      ),
                      onSelected: _isSubmitting
                          ? null
                          : (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatus = status;
                                  _errorMessage = null;
                                });
                              }
                            },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              const Text(
                'Mandatory Action Remark:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('status_remark_field'),
                controller: _remarkController,
                enabled: !_isSubmitting,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _selectedStatus == 'Resolved'
                      ? 'Detailed explanation of work completed (min 5 characters)...'
                      : 'Action taken or progress notes...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'An action remark is required.';
                  }
                  if (_selectedStatus == 'Resolved' && text.length < 5) {
                    return 'Action remark must be at least 5 characters when resolving.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  key: const Key('submit_status_button'),
                  onPressed: (_isSubmitting || widget.allowedTransitions.isEmpty) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Update Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
