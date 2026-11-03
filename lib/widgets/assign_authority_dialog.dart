import 'package:flutter/material.dart';
import 'package:major_project/models/user_model.dart';

class AssignAuthorityDialog extends StatefulWidget {
  final String complaintId;
  final String complaintTitle;
  final List<UserModel> authorityStaff;
  final String? currentAssignedToName;
  final Future<bool> Function(String authorityId, String authorityName, String? remark) onAssign;

  const AssignAuthorityDialog({
    super.key,
    required this.complaintId,
    required this.complaintTitle,
    required this.authorityStaff,
    required this.onAssign,
    this.currentAssignedToName,
  });

  @override
  State<AssignAuthorityDialog> createState() => _AssignAuthorityDialogState();
}

class _AssignAuthorityDialogState extends State<AssignAuthorityDialog> {
  final _remarkController = TextEditingController();
  String? _selectedAuthorityId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _handleAssign() async {
    if (_selectedAuthorityId == null) return;

    final selectedStaff = widget.authorityStaff.firstWhere(
      (u) => u.id == _selectedAuthorityId,
      orElse: () => UserModel(id: _selectedAuthorityId!, name: 'Staff', email: '', role: 'authority'),
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onAssign(
        _selectedAuthorityId!,
        selectedStaff.name,
        _remarkController.text.trim().isNotEmpty ? _remarkController.text.trim() : null,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to assign complaint. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReassign = widget.currentAssignedToName != null &&
        widget.currentAssignedToName!.trim().isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReassign ? Icons.swap_horiz : Icons.person_add_alt_1,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isReassign ? 'Reassign Complaint' : 'Assign Complaint',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.complaintTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isReassign) ...[
              const SizedBox(height: 8),
              Text(
                'Currently assigned to: ${widget.currentAssignedToName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Select Authority Staff',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedAuthorityId,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Choose staff member',
                prefixIcon: const Icon(Icons.manage_accounts_outlined, size: 20),
              ),
              items: widget.authorityStaff.map((staff) {
                final dept = staff.department != null ? ' (${staff.department})' : '';
                return DropdownMenuItem<String>(
                  value: staff.id,
                  child: Text(
                    '${staff.name}$dept',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (val) {
                      setState(() {
                        _selectedAuthorityId = val;
                      });
                    },
            ),
            const SizedBox(height: 16),
            Text(
              'Admin Remark / Instructions (Optional)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarkController,
              enabled: !_isSubmitting,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'e.g., Please inspect immediately due to safety concern',
                hintStyle: TextStyle(
                  color: theme.colorScheme.outline.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedAuthorityId != null && !_isSubmitting)
              ? _handleAssign
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isReassign ? 'Reassign' : 'Assign'),
        ),
      ],
    );
  }
}
