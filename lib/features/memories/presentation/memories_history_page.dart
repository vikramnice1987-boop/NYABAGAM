import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_empty_state.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_models.dart';

class MemoriesHistoryPage extends StatefulWidget {
  const MemoriesHistoryPage({super.key});

  @override
  State<MemoriesHistoryPage> createState() => _MemoriesHistoryPageState();
}

class _MemoriesHistoryPageState extends State<MemoriesHistoryPage> {
  final _searchController = TextEditingController();
  List<MemoryModel> _allMemories = [];
  List<MemoryModel> _filteredMemories = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    final memories = await MemoryRepositoryFactory.current.confirmed();
    if (mounted) {
      setState(() {
        _allMemories = memories;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredMemories = _allMemories.where((m) {
        final matchesQuery = query.isEmpty ||
            m.title.toLowerCase().contains(query) ||
            m.summary.toLowerCase().contains(query) ||
            m.people.any((p) => p.toLowerCase().contains(query)) ||
            m.things.any((t) => t.toLowerCase().contains(query));

        if (!matchesQuery) return false;

        switch (_selectedFilter) {
          case 'People':
            return m.people.isNotEmpty;
          case 'Things':
            return m.things.isNotEmpty;
          case 'Services':
            return m.title.toLowerCase().contains('service') || m.summary.toLowerCase().contains('service');
          default:
            return true;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories & History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: NySpacing.space8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search memories, people, appliances...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: NySpacing.space4),
            child: Row(
              children: ['All', 'People', 'Things', 'Services'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _applyFilters();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const NyLoadingState(message: 'Loading memories...')
                : _filteredMemories.isEmpty
                    ? NyEmptyState(
                        title: 'No memories found',
                        description: _searchController.text.isNotEmpty
                            ? 'No memories matched "${_searchController.text}".'
                            : 'You haven\'t saved any memories yet.',
                        icon: Icons.psychology_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMemories,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(NySpacing.space16),
                          itemCount: _filteredMemories.length,
                          separatorBuilder: (_, _) => const SizedBox(height: NySpacing.space12),
                          itemBuilder: (context, index) {
                            final mem = _filteredMemories[index];
                            return NyCard(
                              onTap: () => context.push('/memory-detail', extra: mem),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          mem.title,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      if (mem.amount != null)
                                        Text(
                                          '?${mem.amount!.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(mem.summary, style: theme.textTheme.bodyMedium),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final p in mem.people) NyEntityChip(label: p, type: NyEntityType.person),
                                      for (final t in mem.things) NyEntityChip(label: t, type: NyEntityType.thing),
                                      for (final o in mem.organizations) NyEntityChip(label: o, type: NyEntityType.organization),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
