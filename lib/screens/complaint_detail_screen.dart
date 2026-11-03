import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/widgets/status_chip.dart';
import 'package:major_project/widgets/priority_badge.dart';
import 'package:major_project/widgets/feedback_dialog.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final TextEditingController _remarkController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().fetchComplaintById(widget.complaintId);
    });
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openPhotoZoom(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white70, size: 48),
                      SizedBox(height: 8),
                      Text('Unable to load full image', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRemark() async {
    final text = _remarkController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final complaintProv = context.read<ComplaintProvider>();

    final success = await complaintProv.addRemark(
      complaintId: widget.complaintId,
      text: text,
      userName: auth.user?.name,
      userRole: auth.user?.role.toLowerCase(),
    );

    if (success && mounted) {
      _remarkController.clear();
      FocusScope.of(context).unfocus();
      // Scroll to bottom of remarks
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showFeedbackModal(ComplaintModel complaint) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => FeedbackDialog(
        complaintId: complaint.id,
        onSubmit: (rating, comments) async {
          return await context.read<ComplaintProvider>().submitFeedback(
                complaintId: complaint.id,
                rating: rating,
                comments: comments,
              );
        },
      ),
    ).then((submitted) {
      if (submitted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Feedback recorded and ticket closed.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _formatSlaCountdown(DateTime? dueDate) {
    if (dueDate == null) return 'SLA: Standard (3 Days)';
    final now = DateTime.now();
    final diff = dueDate.difference(now);

    if (diff.isNegative) {
      final hoursOver = diff.inHours.abs();
      if (hoursOver < 24) {
        return 'SLA Breached ($hoursOver hrs overdue)';
      } else {
        return 'SLA Breached (${(hoursOver / 24).floor()} days overdue)';
      }
    } else {
      if (diff.inDays > 0) {
        return 'Due in ${diff.inDays} ${diff.inDays == 1 ? "day" : "days"}';
      } else if (diff.inHours > 0) {
        return 'Due in ${diff.inHours} ${diff.inHours == 1 ? "hr" : "hrs"}';
      } else {
        return 'Due in ${diff.inMinutes} mins';
      }
    }
  }

  Color _slaColor(DateTime? dueDate) {
    if (dueDate == null) return Colors.grey.shade700;
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return Colors.red.shade700;
    final remainingHours = dueDate.difference(now).inHours;
    if (remainingHours < 24) return Colors.amber.shade800;
    return Colors.teal.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        final complaint = provider.selectedComplaint;
        final isLoading = provider.isLoadingDetail;
        final error = provider.detailError;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              complaint != null ? complaint.complaintId : 'Complaint Detail',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (complaint != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.fetchComplaintById(widget.complaintId),
                  tooltip: 'Refresh details',
                ),
            ],
          ),
          body: isLoading && complaint == null
              ? const Center(child: CircularProgressIndicator())
              : error != null && complaint == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.fetchComplaintById(widget.complaintId),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : complaint == null
                      ? const Center(child: Text('Complaint not found'))
                      : _buildDetailContent(complaint, provider),
        );
      },
    );
  }

  Widget _buildDetailContent(ComplaintModel complaint, ComplaintProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusChip(status: complaint.status),
                        PriorityBadge(priority: complaint.priority),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category & Location
                    Row(
                      children: [
                        Icon(Icons.category_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          complaint.categoryName,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        ),
                        if (complaint.location != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              complaint.location!,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // SLA Countdown Badge
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: _slaColor(complaint.dueDate)),
                        const SizedBox(width: 6),
                        Text(
                          _formatSlaCountdown(complaint.dueDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _slaColor(complaint.dueDate),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.description,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                    ),
                    if (complaint.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lodged on ${dateFormat.format(complaint.createdAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),

              // Feedback Resolution Banner / Card (if Resolved or Closed)
              if (complaint.status == 'Resolved') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Complaint Resolved!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The authority marked this grievance as resolved. Please submit your rating and comments to confirm closure.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        key: const Key('rate_and_close_button'),
                        onPressed: () => _showFeedbackModal(complaint),
                        icon: const Icon(Icons.star, color: Colors.amber),
                        label: const Text('Rate & Close Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (complaint.feedback != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Student Feedback',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < complaint.feedback!.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (complaint.feedback!.comments != null &&
                          complaint.feedback!.comments!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"${complaint.feedback!.comments}"',
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Photo Gallery Section (if any images)
              if (complaint.images.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Attached Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: complaint.images.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final url = complaint.images[idx];
                      return GestureDetector(
                        onTap: () => _openPhotoZoom(context, url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey.shade200,
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Remarks & Activity Timeline
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity & Remarks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    '${complaint.remarks.length} updates',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (complaint.remarks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'No remarks posted yet.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaint.remarks.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final remark = complaint.remarks[index];
                    return _buildRemarkItem(remark);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Bottom Action Bar to post remark (only if not closed)
        if (complaint.status != 'Closed')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('remark_input_field'),
                      controller: _remarkController,
                      enabled: !provider.isPostingRemark,
                      decoration: InputDecoration(
                        hintText: 'Post a remark or update...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _submitRemark(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  provider.isPostingRemark
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          key: const Key('post_remark_button'),
                          icon: const Icon(Icons.send, color: Colors.indigo),
                          onPressed: _submitRemark,
                        ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRemarkItem(RemarkModel remark) {
    final isAuthority = remark.role.toLowerCase() == 'authority' || remark.role.toLowerCase() == 'admin';
    final initial = remark.userName != null && remark.userName!.isNotEmpty
        ? remark.userName![0].toUpperCase()
        : (isAuthority ? 'A' : 'S');

    final timeStr = remark.createdAt != null
        ? DateFormat('MMM dd • hh:mm a').format(remark.createdAt!)
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isAuthority ? Colors.indigo.shade100 : Colors.teal.shade100,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isAuthority ? Colors.indigo.shade800 : Colors.teal.shade800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAuthority ? Colors.indigo.shade50.withValues(alpha: 0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAuthority ? Colors.indigo.shade100 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remark.userName ?? (isAuthority ? 'Authority Officer' : 'Student'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isAuthority ? Colors.indigo.shade900 : Colors.black87,
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  remark.text,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
