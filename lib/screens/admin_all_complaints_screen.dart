import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/widgets/assign_authority_dialog.dart';
import 'package:major_project/widgets/priority_badge.dart';

class AdminAllComplaintsScreen extends StatefulWidget {
  const AdminAllComplaintsScreen({super.key});

  @override
  State<AdminAllComplaintsScreen> createState() => _AdminAllComplaintsScreenState();
}

class _AdminAllComplaintsScreenState extends State<AdminAllComplaintsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  bool _isEscalatedOnly = false;

  final List<String> _statuses = [
    'All',
    'Submitted',
    'Assigned',
    'In Progress',
    'Resolved',
    'Closed',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    complaintProvider.fetchCategories();
    complaintProvider.fetchAuthorityStaff();
    _fetchFilteredComplaints();
  }

  Future<void> _fetchFilteredComplaints() async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    await complaintProvider.fetchAllComplaintsAdmin(
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      status: _selectedStatus != 'All' ? _selectedStatus : null,
      category: _selectedCategory != 'All' ? _selectedCategory : null,
      isEscalated: _isEscalatedOnly ? true : null,
    );
  }

  void _openAssignDialog(ComplaintModel complaint) async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);

    if (complaintProvider.authorityStaff.isEmpty) {
      await complaintProvider.fetchAuthorityStaff();
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AssignAuthorityDialog(
        complaintId: complaint.id,
        complaintTitle: complaint.title,
        authorityStaff: complaintProvider.authorityStaff,
        currentAssignedToName: complaint.assignedToName,
        onAssign: (authId, authName, remark) async {
          return await complaintProvider.assignComplaint(
            complaintId: complaint.id,
            authorityId: authId,
            authorityName: authName,
            remark: remark,
          );
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint ${complaint.complaintId} delegated successfully.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Submitted':
        return Colors.blueGrey;
      case 'Assigned':
        return Colors.blue.shade700;
      case 'In Progress':
        return Colors.amber.shade800;
      case 'Resolved':
        return Colors.green.shade700;
      case 'Closed':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaints = complaintProvider.adminComplaints;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Master Console',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Admin Oversight & Delegation',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _fetchFilteredComplaints,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFilteredComplaints,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by ID or title...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchFilteredComplaints();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _fetchFilteredComplaints(),
                      onChanged: (val) {
                        setState(() {});
                        if (val.isEmpty) {
                          _fetchFilteredComplaints();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips: Statuses & Escalated
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._statuses.map((status) {
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(status),
                                selected: isSelected,
                                selectedColor: theme.colorScheme.primaryContainer,
                                checkmarkColor: theme.colorScheme.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : Colors.black87,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                  _fetchFilteredComplaints();
                                },
                              ),
                            );
                          }),
                          // Escalated Only Toggle Chip
                          FilterChip(
                            avatar: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: _isEscalatedOnly ? Colors.white : Colors.red.shade700,
                            ),
                            label: const Text('Escalated Only'),
                            selected: _isEscalatedOnly,
                            selectedColor: Colors.red.shade700,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: _isEscalatedOnly ? FontWeight.bold : FontWeight.w600,
                              color: _isEscalatedOnly ? Colors.white : Colors.red.shade700,
                            ),
                            side: BorderSide(
                              color: _isEscalatedOnly ? Colors.red.shade700 : Colors.red.shade300,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _isEscalatedOnly = selected;
                              });
                              _fetchFilteredComplaints();
                            },
                          ),
                        ],
                      ),
                    ),
                    if (complaintProvider.categories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: const Text('All Categories'),
                                selected: _selectedCategory == 'All',
                                selectedColor: theme.colorScheme.secondaryContainer,
                                checkmarkColor: theme.colorScheme.secondary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedCategory == 'All' ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedCategory == 'All'
                                      ? theme.colorScheme.onSecondaryContainer
                                      : Colors.black87,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = 'All';
                                  });
                                  _fetchFilteredComplaints();
                                },
                              ),
                            ),
                            ...complaintProvider.categories.map((cat) {
                              final isSelected = _selectedCategory == cat.name;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  selectedColor: theme.colorScheme.secondaryContainer,
                                  checkmarkColor: theme.colorScheme.secondary,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.onSecondaryContainer
                                        : Colors.black87,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? cat.name : 'All';
                                    });
                                    _fetchFilteredComplaints();
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Complaint Tickets Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Tickets (${complaints.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (complaintProvider.isLoadingAdminComplaints)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),

            // List of Complaints or Empty/Error State
            if (complaintProvider.isLoadingAdminComplaints && complaints.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (complaintProvider.adminComplaintsError != null && complaints.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load tickets',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        complaintProvider.adminComplaintsError!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchFilteredComplaints,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (complaints.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No tickets found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try adjusting your search query or filters',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = complaints[index];
                      final statusColor = _getStatusColor(item.status);
                      final isUnassigned = item.status == 'Submitted' ||
                          item.assignedToName == null ||
                          item.assignedToName!.isEmpty;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: item.isEscalated
                                ? Colors.red.shade300
                                : Colors.grey.shade200,
                            width: item.isEscalated ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              '/complaint-detail',
                              arguments: item.id,
                            );
                            _fetchFilteredComplaints();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Complaint ID + Badges
                                Row(
                                  children: [
                                    Text(
                                      item.complaintId,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    PriorityBadge(priority: item.priority),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Title
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),

                                // Category info
                                Row(
                                  children: [
                                    Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.categoryName,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    if (item.department != null && item.department!.isNotEmpty) ...[
                                      Text(' • ', style: TextStyle(color: Colors.grey.shade500)),
                                      Text(
                                        item.department!,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),

                                // Escalation Banner
                                if (item.isEscalated) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ESCALATED',
                                          style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '— SLA Deadline Exceeded',
                                          style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const Divider(height: 20),

                                // Bottom row: Assigned To + Action Button
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: isUnassigned ? Colors.orange.shade800 : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        isUnassigned
                                            ? 'Unassigned'
                                            : 'Assigned: ${item.assignedToName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isUnassigned ? FontWeight.bold : FontWeight.w500,
                                          color: isUnassigned ? Colors.orange.shade800 : Colors.grey.shade800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _openAssignDialog(item),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        side: BorderSide(
                                          color: isUnassigned
                                              ? theme.colorScheme.primary
                                              : Colors.grey.shade400,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: Icon(
                                        isUnassigned ? Icons.person_add_alt_1 : Icons.swap_horiz,
                                        size: 14,
                                        color: isUnassigned
                                            ? theme.colorScheme.primary
                                            : Colors.grey.shade700,
                                      ),
                                      label: Text(
                                        isUnassigned ? 'Assign' : 'Reassign',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isUnassigned
                                              ? theme.colorScheme.primary
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: complaints.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
