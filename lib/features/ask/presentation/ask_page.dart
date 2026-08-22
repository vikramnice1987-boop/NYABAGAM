import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_gateway.dart';
import '../../../core/speech/speech_service.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_elevation.dart';
import '../../../core/theme/ny_motion.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_chip_bar.dart';
import '../../../shared/components/ny_evidence_card.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../../shared/components/ny_section.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_models.dart';

class AskPage extends StatefulWidget {
  const AskPage({super.key});

  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final _queryController = TextEditingController();
  AskResult? _result;
  List<MemoryModel> _matchingEvidence = [];
  bool _isSearching = false;
  bool _isListening = false;
  String _selectedLang = 'en-IN';
  String _voiceStatus = 'Tap microphone to speak your question';

  final List<Map<String, String>> _askLanguages = [
    {'code': 'en-IN', 'label': 'English'},
    {'code': 'ta-IN', 'label': 'Tamil'},
    {'code': 'hi-IN', 'label': 'Hindi'},
  ];

  @override
  void dispose() {
    SpeechService.instance.stopListening();
    _queryController.dispose();
    super.dispose();
  }

  String _deduplicatePhrases(String input) {
    if (input.trim().isEmpty) return '';
    final words = input.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';

    final dedup = <String>[];
    for (int i = 0; i < words.length; i++) {
      if (dedup.isEmpty || dedup.last.toLowerCase() != words[i].toLowerCase()) {
        dedup.add(words[i]);
      }
    }
    for (int phraseLen = 4; phraseLen >= 2; phraseLen--) {
      for (int start = 0; start <= dedup.length - 2 * phraseLen; start++) {
        final p1 = dedup.sublist(start, start + phraseLen).join(' ').toLowerCase();
        final p2 = dedup.sublist(start + phraseLen, start + 2 * phraseLen).join(' ').toLowerCase();
        if (p1 == p2 && p1.isNotEmpty) {
          dedup.removeRange(start + phraseLen, start + 2 * phraseLen);
          start--;
        }
      }
    }
    return dedup.join(' ');
  }

  void _toggleVoiceSearch() {
    if (_isListening) {
      SpeechService.instance.stopListening();
      setState(() {
        _isListening = false;
        _voiceStatus = 'Searching with your question...';
      });
      if (_queryController.text.trim().isNotEmpty) {
        _ask(_queryController.text.trim());
      }
    } else {
      setState(() {
        _isListening = true;
        _voiceStatus = 'Listening in ${_getLanguageLabel(_selectedLang)}... Ask your question now.';
      });
      SpeechService.instance.startListening(
        language: _selectedLang,
        onResult: (transcript, isFinal) {
          if (mounted && transcript.isNotEmpty) {
            final cleaned = _deduplicatePhrases(transcript);
            setState(() {
              _queryController.text = cleaned;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isListening = false;
              _voiceStatus = 'Tap microphone to speak again';
            });
            if (_queryController.text.trim().isNotEmpty) {
              _ask(_queryController.text.trim());
            }
          }
        },
      );
    }
  }

  String _getLanguageLabel(String code) {
    return _askLanguages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'label': code},
    )['label']!;
  }

  Future<void> _ask(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    if (_isListening) {
      SpeechService.instance.stopListening();
      _isListening = false;
    }
    _queryController.text = q;
    setState(() {
      _isSearching = true;
      _result = null;
    });

    try {
      final repo = MemoryRepositoryFactory.current;
      final memories = await repo.search(q);
      _matchingEvidence = memories;

      final evidencePayload = memories.map((m) => {
        'title': m.title,
        'summary': m.summary,
        'people': m.people,
        'things': m.things,
        'organizations': m.organizations,
        'amount': m.amount,
        'date': m.occurredAt?.toIso8601String(),
      }).toList();

      final res = await AiGateway.ask(q, evidencePayload);
      if (mounted) {
        setState(() {
          _result = res;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NyScaffold(
      title: 'Ask NYABAGAM',
      padBottomForNav: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              NySpacing.gutter,
              NySpacing.space8,
              NySpacing.gutter,
              NySpacing.space32,
            ),
            children: <Widget>[
              NyReveal(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const NyGradientText('Find any past detail'),
                    Text(
                      'naturally.',
                      style: NyTypography.displayMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: NySpacing.space10),
                    Text(
                      'Type or speak in English or Tamil. Every answer is grounded strictly in your confirmed memories.',
                      style: NyTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space24),

              NyReveal(
                index: 1,
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.translate_rounded,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: NySpacing.space8),
                    Text(
                      'VOICE LANGUAGE',
                      style: NyTypography.overline.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space10),
              NyReveal(
                index: 1,
                child: NySegmented(
                  labels: _askLanguages.map((l) => l['label']!).toList(),
                  selectedIndex: _askLanguages
                      .indexWhere((l) => l['code'] == _selectedLang),
                  onSelected: (i) {
                    setState(() {
                      _selectedLang = _askLanguages[i]['code']!;
                      if (_isListening) _toggleVoiceSearch();
                    });
                  },
                ),
              ),
              const SizedBox(height: NySpacing.space16),

              NyReveal(index: 2, child: _SearchBar(
                controller: _queryController,
                isListening: _isListening,
                onSubmit: _ask,
                onToggleVoice: _toggleVoiceSearch,
                onClear: () {
                  _queryController.clear();
                  setState(() {
                    _result = null;
                    _matchingEvidence.clear();
                  });
                },
              )),

              if (_isListening) ...<Widget>[
                const SizedBox(height: NySpacing.space12),
                _ListeningBanner(
                  status: _voiceStatus,
                  onSearchNow: _toggleVoiceSearch,
                ),
              ],

              const SizedBox(height: NySpacing.space20),

              NyReveal(
                index: 3,
                child: Wrap(
                  spacing: NySpacing.space8,
                  runSpacing: NySpacing.space8,
                  children: <Widget>[
                    NyFilterPill(
                      label: 'Who serviced my AC?',
                      icon: Icons.ac_unit_rounded,
                      selected: false,
                      onTap: () => _ask('Who serviced my AC?'),
                    ),
                    NyFilterPill(
                      label: 'AC service cost?',
                      icon: Icons.currency_rupee_rounded,
                      selected: false,
                      onTap: () => _ask('How much did AC service cost?'),
                    ),
                    NyFilterPill(
                      label: 'Laptop serviced?',
                      icon: Icons.laptop_mac_rounded,
                      selected: false,
                      onTap: () => _ask('When was my laptop serviced?'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space28),

              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: NySpacing.space32),
                  child: NyLoadingState(
                    message: 'Searching memories and reasoning...',
                  ),
                )
              else if (_result != null) ...<Widget>[
                _AnswerCard(
                  result: _result!,
                  onAction: () => context.push(
                    '/action-approval',
                    extra: _result!.suggestedActions.first,
                  ),
                ),
                const SizedBox(height: NySpacing.space24),
                if (_matchingEvidence.isNotEmpty) ...<Widget>[
                  const NySectionHeader(
                    title: 'Source evidence',
                    subtitle: 'The records this answer was built from',
                    icon: Icons.verified_rounded,
                  ),
                  for (final ev in _matchingEvidence)
                    Padding(
                      padding: const EdgeInsets.only(bottom: NySpacing.space10),
                      child: NyEvidenceCard(
                        title: ev.title,
                        snippet: ev.summary,
                        date: ev.occurredAt ?? ev.createdAt,
                        onTap: () => context.push('/memory-detail', extra: ev),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass search pill. The border and glow shift to the alert colour while the
/// microphone is live, so recording state is unmistakable.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.isListening,
    required this.onSubmit,
    required this.onToggleVoice,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isListening;
  final ValueChanged<String> onSubmit;
  final VoidCallback onToggleVoice;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.isListening
        ? NyColors.statusError
        : theme.colorScheme.primary;

    return AnimatedContainer(
      duration: NyMotion.fast,
      curve: NyMotion.settle,
      padding: const EdgeInsets.symmetric(
        horizontal: NySpacing.space6,
        vertical: NySpacing.space6,
      ),
      decoration: BoxDecoration(
        color: isDark ? NyColors.glassFillDark : NyColors.glassFillLight,
        borderRadius: NyRadius.borderPill,
        border: Border.all(
          color: accent.withValues(alpha: widget.isListening ? 0.95 : 0.45),
          width: widget.isListening ? 1.8 : 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: widget.isListening ? 0.34 : 0.18),
            blurRadius: widget.isListening ? 26 : 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NySpacing.space10),
            child: Icon(Icons.search_rounded, size: 20, color: accent),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmit,
              style: NyTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Ask anything you saved...',
                hintStyle: NyTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.75),
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: NySpacing.space12,
                ),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded),
              onPressed: widget.onClear,
            ),
          _RoundAction(
            icon: widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
            tooltip: widget.isListening ? 'Stop listening' : 'Speak',
            filled: widget.isListening,
            color: widget.isListening
                ? NyColors.statusError
                : theme.colorScheme.secondary,
            onTap: widget.onToggleVoice,
          ),
          const SizedBox(width: NySpacing.space4),
          _RoundAction(
            icon: Icons.arrow_forward_rounded,
            tooltip: 'Search',
            filled: true,
            gradient: true,
            onTap: () => widget.onSubmit(widget.controller.text),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.filled = false,
    this.gradient = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool filled;
  final bool gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient
                ? const LinearGradient(
                    colors: NyColors.accentGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: gradient
                ? null
                : (filled ? tint : tint.withValues(alpha: 0.16)),
            border: filled || gradient
                ? null
                : Border.all(color: tint.withValues(alpha: 0.45)),
            boxShadow: gradient
                ? <BoxShadow>[
                    BoxShadow(
                      color: NyColors.accentGradient[1]
                          .withValues(alpha: 0.44),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Icon(
            icon,
            size: 19,
            color: filled || gradient ? Colors.white : tint,
          ),
        ),
      ),
    );
  }
}

class _ListeningBanner extends StatelessWidget {
  const _ListeningBanner({required this.status, required this.onSearchNow});

  final String status;
  final VoidCallback onSearchNow;

  @override
  Widget build(BuildContext context) {
    const alert = NyColors.statusError;
    return Container(
      padding: const EdgeInsets.all(NySpacing.space12),
      decoration: BoxDecoration(
        color: alert.withValues(alpha: 0.12),
        borderRadius: NyRadius.borderLg,
        border: Border.all(color: alert.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: <Widget>[
          const NyPulseOrb(size: 26),
          const SizedBox(width: NySpacing.space10),
          Expanded(
            child: Text(
              status,
              style: NyTypography.labelMedium.copyWith(color: alert),
            ),
          ),
          const SizedBox(width: NySpacing.space8),
          GestureDetector(
            onTap: onSearchNow,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: NySpacing.space12,
                vertical: NySpacing.space6,
              ),
              decoration: BoxDecoration(
                color: alert,
                borderRadius: NyRadius.borderPill,
              ),
              child: Text(
                'Search now',
                style: NyTypography.labelSmall.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The grounded answer. Highest-elevation glass on the screen, tinted with the
/// accent so it clearly outranks the evidence beneath it.
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.result, required this.onAction});

  final AskResult result;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NyCard(
      level: NyGlassLevel.floating,
      padding: const EdgeInsets.all(NySpacing.space20),
      tint: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          NyColors.orbIndigo.withValues(alpha: 0.22),
          NyColors.orbCyan.withValues(alpha: 0.06),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: NySpacing.space8),
              Expanded(
                child: Text(
                  'GROUNDED ANSWER',
                  style: NyTypography.overline.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NySpacing.space8,
                  vertical: NySpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: NyColors.statusSuccess.withValues(alpha: 0.16),
                  borderRadius: NyRadius.borderPill,
                  border: Border.all(
                    color: NyColors.statusSuccess.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'VERIFIED',
                  style: NyTypography.labelSmall.copyWith(
                    color: NyColors.statusSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NySpacing.space14),
          Text(
            result.answer,
            style: NyTypography.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.6,
            ),
          ),
          if (result.suggestedActions.isNotEmpty) ...<Widget>[
            const SizedBox(height: NySpacing.space20),
            NyButton(
              label: result.suggestedActions.first.title,
              icon: Icons.chat_rounded,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
