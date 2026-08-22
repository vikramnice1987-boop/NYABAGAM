import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_chip_bar.dart';
import '../../../shared/components/ny_empty_state.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../../shared/components/ny_scaffold.dart';
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
          case 'Warranties':
            return m.warrantyExpiresAt != null || m.serviceDueAt != null;
          case 'Services':
            return m.title.toLowerCase().contains('service') ||
                m.summary.toLowerCase().contains('service') ||
                m.title.toLowerCase().contains('repair');
          default:
            return true;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const filters = <String>['All', 'People', 'Things', 'Warranties', 'Services'];

    return NyScaffold(
      title: 'Memories',
      padBottomForNav: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NySpacing.gutter,
              NySpacing.space4,
              NySpacing.gutter,
              NySpacing.space12,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search memories, people, appliances...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          NyChipBar(
            labels: filters,
            selectedIndex: filters.indexOf(_selectedFilter),
            onSelected: (i) {
              setState(() {
                _selectedFilter = filters[i];
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: NySpacing.space12),
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
                          padding: const EdgeInsets.fromLTRB(
                            NySpacing.gutter,
                            NySpacing.space4,
                            NySpacing.gutter,
                            NySpacing.space24,
                          ),
                          itemCount: _filteredMemories.length,
                          separatorBuilder: (_, _) => const SizedBox(height: NySpacing.space12),
                          itemBuilder: (context, index) {
                            final mem = _filteredMemories[index];
                            return NyCard(
                              // Rows opt out of blur: one BackdropFilter per
                              // list item would make the scroll janky.
                              blur: false,
                              onTap: () async {
                                await context.push('/memory-detail', extra: mem);
                                _loadMemories();
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          mem.title,
                                          style: NyTypography.titleMedium.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (mem.amount != null) ...[
                                        const SizedBox(width: NySpacing.space8),
                                        Text(
                                          'Rs. ${mem.amount!.toStringAsFixed(0)}',
                                          style: NyTypography.numeric.copyWith(
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: NySpacing.space8),
                                  Text(
                                    mem.summary,
                                    style: NyTypography.bodySmall.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: NySpacing.space12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final p in mem.people) NyEntityChip(label: p, type: NyEntityType.person),
                                      for (final t in mem.things) NyEntityChip(label: t, type: NyEntityType.thing),
                                      for (final o in mem.organizations) NyEntityChip(label: o, type: NyEntityType.organization),
                                      if (mem.warrantyExpiresAt != null)
                                        NyEntityChip(
                                          label: 'Warranty: ${mem.warrantyExpiresAt!.year}-${mem.warrantyExpiresAt!.month.toString().padLeft(2, '0')}-${mem.warrantyExpiresAt!.day.toString().padLeft(2, '0')}',
                                          type: NyEntityType.place,
                                        ),
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
