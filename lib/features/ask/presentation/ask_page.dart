import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/speech/speech_service.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_evidence_card.dart';
import '../../../shared/components/ny_loading_state.dart';
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
  String _voiceStatus = 'Tap mic to speak your question';

  final List<Map<String, String>> _askLanguages = [
    {'code': 'en-IN', 'label': 'English'},
    {'code': 'ta-IN', 'label': 'à®¤à®®à®¿à®´à¯ (Tamil)'},
    {'code': 'hi-IN', 'label': 'à¤¹à¤¿à¤‚à¤¦à¥€ (Hindi)'},
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
              _voiceStatus = 'Tap mic to speak again';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask NYABAGAM', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: 12),
          children: [
            Text(
              'Find any past detail naturally.',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Type or speak your question in English or Tamil. Answers are strictly grounded in your confirmed memories.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(170),
              ),
            ),
            const SizedBox(height: NySpacing.space16),

            // Voice Language Selector Pills
            Row(
              children: [
                const Icon(Icons.language_rounded, size: 16, color: NyColors.accentLight),
                const SizedBox(width: 6),
                const Text('Voice Language:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _askLanguages.map((lang) {
                        final isSel = _selectedLang == lang['code'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: isSel,
                            label: Text(lang['label']!),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              color: isSel ? Colors.white : theme.colorScheme.onSurface,
                            ),
                            selectedColor: theme.colorScheme.primary,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedLang = lang['code']!;
                                  if (_isListening) {
                                    _toggleVoiceSearch();
                                  }
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NySpacing.space12),

            // Search Bar with Both Voice & Type Actions
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: NyRadius.borderMd,
                border: Border.all(
                  color: _isListening
                      ? NyColors.statusError
                      : theme.colorScheme.outline.withAlpha(90),
                  width: _isListening ? 2 : 1,
                ),
                boxShadow: [
                  if (_isListening)
                    BoxShadow(
                      color: NyColors.statusError.withAlpha(80),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search_rounded, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _ask,
                      decoration: const InputDecoration(
                        hintText: 'Type or tap mic to speak question...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_queryController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _queryController.clear();
                        setState(() {
                          _result = null;
                          _matchingEvidence.clear();
                        });
                      },
                    ),

                  // Mic Button (Voice Search)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _isListening
                            ? NyColors.statusError
                            : theme.colorScheme.primaryContainer,
                        foregroundColor: _isListening
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                      tooltip: _isListening ? 'Stop Listening' : 'Voice Search',
                      icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, size: 20),
                      onPressed: _toggleVoiceSearch,
                    ),
                  ),

                  // Submit Search Button
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      tooltip: 'Search',
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      onPressed: () => _ask(_queryController.text),
                    ),
                  ),
                ],
              ),
            ),

            // Live Voice Recording Status Banner
            if (_isListening) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: NyColors.statusError.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NyColors.statusError.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record_rounded, color: NyColors.statusError, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _voiceStatus,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NyColors.statusError),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleVoiceSearch,
                      child: const Text('Stop & Search', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: NySpacing.space16),

            // Example Queries (Both English & Tamil)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: const Text('Who serviced my AC?'),
                  onPressed: () => _ask('Who serviced my AC?'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.currency_rupee_rounded, size: 14),
                  label: const Text('How much did AC service cost?'),
                  onPressed: () => _ask('How much did AC service cost?'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.laptop_mac_rounded, size: 14),
                  label: const Text('When was my laptop serviced?'),
                  onPressed: () => _ask('When was my laptop serviced?'),
                ),
              ],
            ),
            const SizedBox(height: NySpacing.space24),

            // Search Loading State
            if (_isSearching)
              const NyLoadingState(message: 'Searching memories and reasoning with AI...')
            else if (_result != null) ...[
              // Grounded Answer Card
              NyCard(
                backgroundColor: theme.colorScheme.primaryContainer.withAlpha(100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 18, color: NyColors.accentLight),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Grounded Answer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: NyColors.accentLight,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: NyColors.statusSuccess.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Confidence: High', style: TextStyle(fontSize: 11, color: NyColors.statusSuccess, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: NySpacing.space12),
                    Text(
                      _result!.answer,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    if (_result!.suggestedActions.isNotEmpty) ...[
                      const SizedBox(height: NySpacing.space16),
                      NyButton(
                        label: _result!.suggestedActions.first.title,
                        icon: Icons.chat_rounded,
                        onPressed: () => context.push(
                          '/action-approval',
                          extra: _result!.suggestedActions.first,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space20),

              // Source Evidence Cards
              if (_matchingEvidence.isNotEmpty) ...[
                Text(
                  'Source Evidence Records',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (final ev in _matchingEvidence)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NyEvidenceCard(
                      title: ev.title,
                      snippet: ev.summary,
                      date: ev.occurredAt ?? ev.createdAt,
                      onTap: () => context.push('/memory-detail', extra: ev),
                    ),
                  ),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}