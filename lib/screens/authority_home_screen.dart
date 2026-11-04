import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/providers/notification_provider.dart';
import 'package:major_project/widgets/complaint_card.dart';
import 'package:major_project/widgets/empty_state_view.dart';
import 'package:major_project/widgets/skeleton_loading.dart';
import 'package:major_project/widgets/status_update_bottom_sheet.dart';

class AuthorityHomeScreen extends StatefulWidget {
  const AuthorityHomeScreen({super.key});

  @override
  State<AuthorityHomeScreen> createState() => _AuthorityHomeScreenState();
}

class _AuthorityHomeScreenState extends State<AuthorityHomeScreen> {
  String _selectedFilter = 'All'; // 'All', 'Assigned', 'In Progress', 'Resolved'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().fetchAssignedComplaints();
      context.read<NotificationProvider>().fetchNotifications(silent: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ComplaintModel> _filterList(List<ComplaintModel> list) {
    var filtered = list;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((c) => c.status == _selectedFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((c) {
        final matchesId = c.complaintId.toLowerCase().contains(q);
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesCat = c.categoryName.toLowerCase().contains(q);
        final matchesLoc = c.location?.toLowerCase().contains(q) ?? false;
        return matchesId || matchesTitle || matchesCat || matchesLoc;
      }).toList();
    }
    return filtered;
  }

  void _openStatusBottomSheet(ComplaintModel complaint, ComplaintProvider provider) {
    final allowed = provider.getAllowedTransitions(complaint.status);
    if (allowed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint ${complaint.complaintId} is in a terminal state (${complaint.status}).'),
        ),
      );
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatusUpdateBottomSheet(
        complaint: complaint,
        allowedTransitions: allowed,
        onUpdateStatus: (nextStatus, remark) async {
          return await provider.updateComplaintStatus(
            complaintId: complaint.id,
            nextStatus: nextStatus,
            remark: remark,
          );
        },
      ),
    ).then((updated) {
      if (updated == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint status successfully updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;

    final assignedList = complaintProvider.assignedComplaints;
    final filteredList = _filterList(assignedList);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Authority Console',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('authority_notifications_button'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (notifProvider.hasUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: RefreshIndicator(
        onRefresh: () async {
          await complaintProvider.fetchAssignedComplaints(refresh: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome & Staff Department Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade800, Colors.indigo.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            child: Text(
                              (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user?.name ?? "Officer"}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.department ?? 'Department Maintenance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KPI Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            label: 'Assigned',
                            count: complaintProvider.assignedCount,
                            color: Colors.blue.shade700,
                            icon: Icons.assignment_ind_rounded,
                            onTap: () => setState(() => _selectedFilter = 'Assigned'),
                            isSelected: _selectedFilter == 'Assigned',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildKpiCard(
                            label: 'In Progress',
                            count: complaintProvider.inProgressCount,
                            color: Colors.amber.shade800,
                            icon: Icons.engineering_rounded,
                            onTap: () => setState(() => _selectedFilter = 'In Progress'),
                            isSelected: _selectedFilter == 'In Progress',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildKpiCard(
                            label: 'Resolved',
                            count: complaintProvider.resolvedCount,
                            color: Colors.green.shade700,
                            icon: Icons.task_alt_rounded,
                            onTap: () => setState(() => _selectedFilter = 'Resolved'),
                            isSelected: _selectedFilter == 'Resolved',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search & Filter
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search queue by ID, title, or category...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', count: assignedList.length),
                          const SizedBox(width: 8),
                          _buildFilterChip('Assigned', count: complaintProvider.assignedCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('In Progress', count: complaintProvider.inProgressCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('Resolved', count: complaintProvider.resolvedCount),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Assigned Tickets Queue (${filteredList.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Queue List or Empty State
            if (complaintProvider.isLoadingAssigned && assignedList.isEmpty)
              const SliverToBoxAdapter(
                child: ComplaintListSkeleton(count: 3),
              )
            else if (filteredList.isEmpty)
              SliverFillRemaining(
                child: EmptyStateView(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'No tickets found in $_selectedFilter queue',
                  message: _searchQuery.isNotEmpty
                      ? 'No matches for "$_searchQuery"'
                      : 'All assigned tasks in this state are clear.',
                  actionLabel: 'Refresh Queue',
                  onAction: () => complaintProvider.fetchAssignedComplaints(refresh: true),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Stack(
                          children: [
                            ComplaintCard(
                              complaint: item,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/complaint-detail',
                                  arguments: item.id,
                                );
                                complaintProvider.fetchAssignedComplaints(refresh: true);
                              },
                            ),
                            Positioned(
                              top: 14,
                              right: 14,
                              child: ElevatedButton.icon(
                                key: Key('update_status_btn_${item.id}'),
                                onPressed: () => _openStatusBottomSheet(item, complaintProvider),
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Update'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade50,
                                  foregroundColor: Colors.indigo.shade900,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: filteredList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {required int count}) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: Colors.indigo.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.indigo.shade900 : Colors.black87,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }
}
