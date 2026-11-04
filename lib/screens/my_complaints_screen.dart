import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/widgets/complaint_card.dart';
import 'package:major_project/widgets/empty_state_view.dart';
import 'package:major_project/widgets/skeleton_loading.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      if (provider.myComplaints.isEmpty) {
        provider.fetchMyComplaints();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ComplaintModel> _filterComplaints(ComplaintProvider provider) {
    List<ComplaintModel> baseList;
    switch (_selectedFilter) {
      case 'Active':
        baseList = provider.activeComplaints;
        break;
      case 'Resolved':
        baseList = provider.resolvedComplaints;
        break;
      case 'Closed':
        baseList = provider.closedComplaints;
        break;
      case 'All':
      default:
        baseList = provider.myComplaints;
        break;
    }

    if (_searchQuery.trim().isEmpty) {
      return baseList;
    }

    final query = _searchQuery.toLowerCase().trim();
    return baseList.where((c) {
      final matchesId = c.complaintId.toLowerCase().contains(query);
      final matchesTitle = c.title.toLowerCase().contains(query);
      final matchesCat = c.categoryName.toLowerCase().contains(query);
      final matchesLoc = (c.location ?? '').toLowerCase().contains(query);
      return matchesId || matchesTitle || matchesCat || matchesLoc;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintProvider>(context);
    final filteredList = _filterComplaints(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.fetchMyComplaints(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('my_complaints_fab'),
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/new-complaint');
          if (created == true) {
            provider.fetchMyComplaints(refresh: true);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Raise Grievance'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by ID, title, or category...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', count: provider.totalComplaintsCount),
                const SizedBox(width: 8),
                _buildFilterChip('Active', count: provider.activeComplaintsCount),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', count: provider.resolvedComplaintsCount),
                const SizedBox(width: 8),
                _buildFilterChip('Closed', count: provider.closedComplaintsCount),
              ],
            ),
          ),
          const Divider(height: 1),

          // Complaints List with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchMyComplaints(refresh: true),
              child: provider.isLoadingComplaints && provider.myComplaints.isEmpty
                  ? const ComplaintListSkeleton(count: 4)
                  : filteredList.isEmpty
                      ? EmptyStateView(
                          icon: Icons.inbox_outlined,
                          title: 'No complaints found',
                          message: _searchQuery.isNotEmpty
                              ? 'No results matching "$_searchQuery"'
                              : 'No grievances in the "$_selectedFilter" filter.',
                          actionLabel: 'Refresh List',
                          onAction: () => provider.fetchMyComplaints(refresh: true),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filteredList.length,
                          itemBuilder: (ctx, index) {
                            final complaint = filteredList[index];
                            return ComplaintCard(
                              complaint: complaint,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/complaint-detail',
                                  arguments: complaint.id,
                                );
                                provider.fetchMyComplaints(refresh: true);
                              },
                            );
                          },
                        ),
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
      key: Key('filter_chip_$label'),
      label: Text(count > 0 ? '$label ($count)' : label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Colors.grey.shade700,
      ),
    );
  }
}
