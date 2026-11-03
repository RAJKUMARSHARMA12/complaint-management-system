import 'package:flutter/material.dart';

class FeedbackDialog extends StatefulWidget {
  final String complaintId;
  final Future<bool> Function(int rating, String? comments) onSubmit;

  const FeedbackDialog({
    super.key,
    required this.complaintId,
    required this.onSubmit,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Please select a star rating (1 to 5).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onSubmit(
      _rating,
      _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Failed to submit feedback. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.rate_review, color: Colors.amber),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Rate Resolution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How satisfied are you with the resolution of this grievance?',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    key: Key('feedback_star_$starIndex'),
                    icon: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      color: starIndex <= _rating ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _rating = starIndex;
                              _errorMessage = null;
                            });
                          },
                  );
                }),
              ),
            ),
            if (_rating > 0)
              Center(
                child: Text(
                  _ratingDescription(_rating),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ratingColor(_rating),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('feedback_comments_field'),
              controller: _commentController,
              enabled: !_isSubmitting,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share remarks or comments (optional)',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
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
          key: const Key('feedback_submit_button'),
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit & Close'),
        ),
      ],
    );
  }

  String _ratingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Very Dissatisfied';
      case 2:
        return 'Dissatisfied';
      case 3:
        return 'Neutral';
      case 4:
        return 'Satisfied';
      case 5:
        return 'Highly Satisfied';
      default:
        return '';
    }
  }

  Color _ratingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating == 3) return Colors.orange;
    return Colors.green;
  }
}
