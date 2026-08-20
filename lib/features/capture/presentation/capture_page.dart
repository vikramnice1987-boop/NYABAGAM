import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _textController = TextEditingController();
  bool _isRecording = false;
  bool _isUnderstanding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording) {
        if (_textController.text.isEmpty) {
          _textController.text = 'Ravi serviced my AC today for ₹800.';
        }
      }
    });
  }

  Future<void> _continueWithUnderstanding() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write or record a memory first.')),
      );
      return;
    }

    setState(() => _isUnderstanding = true);
    try {
      final candidate = await AiGateway.understand(content);
      if (mounted) {
        context.push('/understand', extra: candidate);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process this capture. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUnderstanding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Memory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Write Thought'),
            Tab(icon: Icon(Icons.mic), text: 'Voice Note'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(NySpacing.space20),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Text Capture Tab
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'What would you like to remember?',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your words become a reviewable candidate. Nothing is saved until you confirm.',
                      ),
                      const SizedBox(height: NySpacing.space16),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Ravi serviced my AC today for ₹800.',
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Voice Capture Tab
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 64,
                        color: _isRecording ? NyColors.statusError : theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording ? 'Listening & Recording...' : 'Tap to Record Voice Note',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRecording ? 'Speak naturally about the event or detail.' : 'Capture details hands-free while on the move.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: NySpacing.space24),
                      IconButton.filled(
                        iconSize: 36,
                        onPressed: _toggleVoiceRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        style: IconButton.styleFrom(
                          backgroundColor: _isRecording ? NyColors.statusError : NyColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(NySpacing.space20),
                        ),
                      ),
                      if (_textController.text.isNotEmpty) ...[
                        const SizedBox(height: NySpacing.space24),
                        NyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transcript Preview:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(_textController.text, style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space16),
            NyButton(
              label: _isUnderstanding ? 'Understanding with AI...' : 'Review Memory Candidate',
              isLoading: _isUnderstanding,
              onPressed: _continueWithUnderstanding,
            ),
          ],
        ),
      ),
    );
  }
}