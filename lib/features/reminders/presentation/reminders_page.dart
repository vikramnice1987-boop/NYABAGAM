import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_models.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<MemoryModel> _allReminders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Expiring Soon (<= 2 Days)', 'Appliances', 'Vehicles', 'Electronics'];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final repo = MemoryRepositoryFactory.current;
    final all = await repo.getWarrantiesAndReminders();
    if (mounted) {
      setState(() {
        _allReminders = all;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchWhatsApp(String phone, String machineName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = Uri.encodeComponent(
      'Hi, regarding my $machineName service/warranty: could you please check and assist?',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp for $phone')),
        );
      }
    }
  }

  List<MemoryModel> get _filteredList {
    final now = DateTime.now();
    if (_selectedFilter == 'Expiring Soon (<= 2 Days)') {
      return _allReminders.where((m) {
        if (m.warrantyExpiresAt != null) {
          final diff = m.warrantyExpiresAt!.difference(now).inDays;
          if (diff <= 2) return true;
        }
        if (m.serviceDueAt != null) {
          final diff = m.serviceDueAt!.difference(now).inDays;
          if (diff <= 2) return true;
        }
        return false;
      }).toList();
    }
    if (_selectedFilter == 'Appliances') {
      return _allReminders.where((m) {
        final lower = '${m.title} ${m.machineType} ${m.things.join(" ")}'.toLowerCase();
        return lower.contains('ac') || lower.contains('fridge') || lower.contains('refrigerator') ||
            lower.contains('washing') || lower.contains('geyser') || lower.contains('purifier') ||
            lower.contains('microwave') || lower.contains('inverter') || lower.contains('fan');
      }).toList();
    }
    if (_selectedFilter == 'Vehicles') {
      return _allReminders.where((m) {
        final lower = '${m.title} ${m.machineType} ${m.things.join(" ")}'.toLowerCase();
        return lower.contains('car') || lower.contains('bike') || lower.contains('scooter') || lower.contains('motorcycle');
      }).toList();
    }
    if (_selectedFilter == 'Electronics') {
      return _allReminders.where((m) {
        final lower = '${m.title} ${m.machineType} ${m.things.join(" ")}'.toLowerCase();
        return lower.contains('laptop') || lower.contains('phone') || lower.contains('tv') || lower.contains('computer');
      }).toList();
    }
    return _allReminders;
  }

  List<MemoryModel> get _urgentList {
    final now = DateTime.now();
    return _allReminders.where((m) {
      if (m.warrantyExpiresAt != null) {
        final diff = m.warrantyExpiresAt!.difference(now).inDays;
        if (diff <= 2) return true;
      }
      if (m.serviceDueAt != null) {
        final diff = m.serviceDueAt!.difference(now).inDays;
        if (diff <= 2) return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final urgent = _urgentList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranties & Reminders', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReminders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const NyLoadingState(message: 'Loading machine warranties and reminders...')
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: 12),
                children: [
                  // Header
                  Text(
                    'Machine & Appliance Lifecycle',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proactive 2-day early alerts for warranties, service renewals, and scheduled maintenance.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
                  ),
                  const SizedBox(height: NySpacing.space16),

                  // ðŸš¨ Urgent 2-Day Expiry Alerts Section
                  if (urgent.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NyColors.statusError.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NyColors.statusError.withAlpha(140), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: NyColors.statusError, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ðŸš¨ Action Required (${urgent.length} Machine Alert${urgent.length > 1 ? "s" : ""})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: NyColors.statusError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'The following machine warranty or service expires within 2 days. Please check and schedule inspection:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),

                          for (final m in urgent)
                            _buildUrgentCard(m, theme, now),
                        ],
                      ),
                    ),
                    const SizedBox(height: NySpacing.space20),
                  ],

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSel = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? NyColors.accentLight : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel ? NyColors.accentLight : theme.colorScheme.outline.withAlpha(80),
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: NySpacing.space16),

                  // All Tracked Machines List
                  if (_filteredList.isEmpty) ...[
                    NyCard(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const Icon(Icons.shield_outlined, size: 44, color: NyColors.accentLight),
                          const SizedBox(height: 10),
                          const Text(
                            'No machine reminders found in this category.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capture a new invoice, bill, or service note to start tracking.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: NyColors.accentLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Machine / Bill', style: TextStyle(fontWeight: FontWeight.w800)),
                            onPressed: () => context.push('/capture'),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ] else ...[
                    for (final m in _filteredList)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMachineCard(m, theme, now),
                      ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/capture'),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Track New Machine', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: NyColors.accentLight,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildUrgentCard(MemoryModel m, ThemeData theme, DateTime now) {
    final machineName = m.machineType ?? (m.things.isNotEmpty ? m.things.first : m.title);
    final daysRemaining = m.warrantyDaysRemaining ?? m.serviceDaysRemaining ?? 0;
    final isExpired = daysRemaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NyColors.statusError.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconForMachine(machineName), size: 18, color: NyColors.statusError),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  machineName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isExpired ? NyColors.statusError : NyColors.statusWarning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isExpired ? 'EXPIRED' : (daysRemaining == 0 ? 'EXPIRES TODAY' : 'EXPIRES IN $daysRemaining DAYS'),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            m.summary,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (m.contactPhone != null && m.contactPhone!.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NyColors.statusSuccess,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 14),
                    label: const Text('WhatsApp Tech', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    onPressed: () => _launchWhatsApp(m.contactPhone!, machineName),
                  ),
                ),
              if (m.contactPhone != null && m.contactPhone!.isNotEmpty)
                const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 14),
                  label: const Text('View Record', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => context.push('/memory-detail', extra: m),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMachineCard(MemoryModel m, ThemeData theme, DateTime now) {
    final machineName = m.machineType ?? (m.things.isNotEmpty ? m.things.first : m.title);
    final hasWarranty = m.warrantyExpiresAt != null;
    final hasService = m.serviceDueAt != null;
    final wDays = m.warrantyDaysRemaining;

    return NyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NyColors.accentLight.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconForMachine(machineName), size: 20, color: NyColors.accentLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      machineName,
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(150)),
                    ),
                  ],
                ),
              ),
              if (hasWarranty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (wDays != null && wDays <= 2)
                        ? (wDays < 0 ? NyColors.statusError.withAlpha(40) : NyColors.statusWarning.withAlpha(40))
                        : NyColors.statusSuccess.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    wDays != null && wDays <= 2
                        ? (wDays < 0 ? 'Expired' : 'Expires in ${wDays}d')
                        : (wDays != null ? '$wDays days valid' : 'Active'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: (wDays != null && wDays <= 2)
                          ? (wDays < 0 ? NyColors.statusError : NyColors.statusWarning)
                          : NyColors.statusSuccess,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            m.summary,
            style: const TextStyle(fontSize: 12, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Lifecycle Details
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (hasWarranty) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Warranty Expiry:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        Text(
                          '${m.warrantyExpiresAt!.year}-${m.warrantyExpiresAt!.month.toString().padLeft(2, '0')}-${m.warrantyExpiresAt!.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NyColors.accentLight),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasService) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Service Due:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        Text(
                          '${m.serviceDueAt!.year}-${m.serviceDueAt!.month.toString().padLeft(2, '0')}-${m.serviceDueAt!.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NyColors.entityPerson),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!hasWarranty && !hasService) ...[
                  const Expanded(
                    child: Text('No specific warranty date set.', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (m.contactPhone != null && m.contactPhone!.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: NyColors.statusSuccess),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('WhatsApp Tech', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => _launchWhatsApp(m.contactPhone!, machineName),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () => context.push('/memory-detail', extra: m),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForMachine(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit_rounded;
    if (lower.contains('car')) return Icons.directions_car_rounded;
    if (lower.contains('bike') || lower.contains('motorcycle') || lower.contains('scooter')) return Icons.two_wheeler_rounded;
    if (lower.contains('laptop') || lower.contains('computer')) return Icons.laptop_mac_rounded;
    if (lower.contains('phone') || lower.contains('mobile')) return Icons.phone_android_rounded;
    if (lower.contains('fridge') || lower.contains('refrigerator')) return Icons.kitchen_rounded;
    if (lower.contains('washing')) return Icons.local_laundry_service_rounded;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv_rounded;
    if (lower.contains('purifier') || lower.contains('water')) return Icons.water_drop_rounded;
    if (lower.contains('inverter') || lower.contains('battery')) return Icons.battery_charging_full_rounded;
    if (lower.contains('geyser')) return Icons.hot_tub_rounded;
    return Icons.settings_suggest_rounded;
  }
}