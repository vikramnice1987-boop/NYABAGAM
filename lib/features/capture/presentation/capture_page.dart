import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/speech/speech_service.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
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
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  bool _isRecording = false;
  bool _isUnderstanding = false;
  String _selectedLanguageCode = 'en-IN'; // Defaulting to English (India)
  String _liveSpeechStatus = 'Tap the microphone to speak';
  String? _attachedFileName;
  Uint8List? _attachedFileBytes;
  String? _attachedFileBase64;
  String _attachmentType = 'image';

  final List<Map<String, String>> _supportedLanguages = [
    {'code': 'en-IN', 'label': 'English', 'sub': 'en-IN'},
    {'code': 'ta-IN', 'label': 'Tamil', 'sub': 'தமிழ்'},
    {'code': 'hi-IN', 'label': 'Hindi', 'sub': 'हिंदी'},
    {'code': 'te-IN', 'label': 'Telugu', 'sub': 'తెలుగు'},
    {'code': 'en-US', 'label': 'English (US)', 'sub': 'en-US'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    SpeechService.instance.stopListening();
    _tabController.dispose();
    _textController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _attachedFileName = photo.name;
          _attachedFileBytes = bytes;
          _attachedFileBase64 = base64Encode(bytes);
          _attachmentType = 'image';
          if (_textController.text.isEmpty) {
            _textController.text = 'Photo: ${photo.name}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera access error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachedFileName = image.name;
          _attachedFileBytes = bytes;
          _attachedFileBase64 = base64Encode(bytes);
          _attachmentType = 'image';
          if (_textController.text.isEmpty) {
            _textController.text = 'Document: ${image.name}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e')),
        );
      }
    }
  }

  String _deduplicateWords(String input) {
    final words = input.split(RegExp(r'\s+'));
    final unique = <String>[];
    for (final w in words) {
      final trimmed = w.trim();
      if (trimmed.isEmpty) continue;
      if (unique.isEmpty || unique.last.toLowerCase() != trimmed.toLowerCase()) {
        unique.add(trimmed);
      }
    }
    return unique.join(' ');
  }

  void _toggleVoiceRecording() {
    if (_isRecording) {
      SpeechService.instance.stopListening();
      setState(() {
        _isRecording = false;
        _liveSpeechStatus = 'Recording finished. Review or edit text below.';
      });
    } else {
      setState(() {
        _isRecording = true;
        _liveSpeechStatus = 'Listening in ${_getLanguageLabel(_selectedLanguageCode)}... Speak now.';
      });
      SpeechService.instance.startListening(
        language: _selectedLanguageCode,
        onResult: (transcript, isFinal) {
          if (mounted && transcript.isNotEmpty) {
            setState(() {
              _textController.text = _deduplicateWords(transcript);
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isRecording = false;
              _liveSpeechStatus = 'Tap microphone to speak again';
            });
          }
        },
      );
    }
  }

  String _getLanguageLabel(String code) {
    return _supportedLanguages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'label': code},
    )['label']!;
  }

  void _removeAttachment() {
    setState(() {
      _attachedFileName = null;
      _attachedFileBytes = null;
      _attachedFileBase64 = null;
    });
  }

  Future<void> _continueWithUnderstanding() async {
    final content = _deduplicateWords(_textController.text.trim());
    if (content.isEmpty && _attachedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write text, speak into the mic, or attach a photo.')),
      );
      return;
    }

    final promptToUnderstand = content.isNotEmpty
        ? content
        : 'Attached document: ${_attachedFileName ?? "Document"}';

    setState(() => _isUnderstanding = true);
    try {
      final candidate = await AiGateway.understand(promptToUnderstand);

      final candidateWithDetails = candidate.copyWith(
        attachmentBase64: _attachedFileBase64,
        attachmentName: _attachedFileName,
        attachmentType: _attachmentType,
        contactPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : candidate.contactPhone,
      );

      if (mounted) {
        context.push('/understand', extra: candidateWithDetails);
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
        title: const Text('Capture Memory', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(180),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.edit_note_rounded, size: 18), text: 'Text'),
                Tab(icon: Icon(Icons.mic_rounded, size: 18), text: 'Voice'),
                Tab(icon: Icon(Icons.photo_camera_rounded, size: 18), text: 'Camera / Scan'),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(NySpacing.space16),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Text Capture
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'What would you like to remember?',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type in English, Tamil, or any language. AI will extract structured facts.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
                        ),
                        const SizedBox(height: NySpacing.space16),

                        TextField(
                          controller: _textController,
                          minLines: 5,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'e.g., Ravi serviced my AC today for Rs. 800\nor Doctor John prescribed medication on Aug 20.',
                            border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                          ),
                        ),
                        const SizedBox(height: NySpacing.space16),

                        _buildPhoneInputCard(theme),
                      ],
                    ),
                  ),

                  // Tab 2: Multi-Language Voice Note Capture
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Language Selector with Segmented Chips
                        NyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.language_rounded, size: 18, color: NyColors.accentLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Speech Language:',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _supportedLanguages.map((lang) {
                                  final isSelected = _selectedLanguageCode == lang['code'];
                                  return ChoiceChip(
                                    selected: isSelected,
                                    label: Text('${lang['label']} (${lang['sub']})'),
                                    labelStyle: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 12,
                                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                    ),
                                    selectedColor: theme.colorScheme.primary,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedLanguageCode = lang['code']!;
                                          if (_isRecording) {
                                            _toggleVoiceRecording();
                                          }
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NySpacing.space20),

                        // Glowing Animated Microphone Button
                        GestureDetector(
                          onTap: _toggleVoiceRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.all(_isRecording ? 28 : 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording
                                  ? NyColors.statusError
                                  : theme.colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? NyColors.statusError : theme.colorScheme.primary).withAlpha(100),
                                  blurRadius: _isRecording ? 30 : 12,
                                  spreadRadius: _isRecording ? 8 : 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: NySpacing.space16),

                        Text(
                          _isRecording ? 'Listening in ${_getLanguageLabel(_selectedLanguageCode)}...' : 'Tap to Start Speaking',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _isRecording ? NyColors.statusError : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _liveSpeechStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: NySpacing.space20),

                        TextField(
                          controller: _textController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: 'Live Transcript (Editable):',
                            hintText: 'Speak into your microphone in ${_getLanguageLabel(_selectedLanguageCode)}...',
                            border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                          ),
                        ),
                        const SizedBox(height: NySpacing.space16),

                        _buildPhoneInputCard(theme),
                      ],
                    ),
                  ),

                  // Tab 3: Camera & File Upload
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Scan Bill, Warranty, or Appliance',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Attach a photo of receipt or nameplate to preserve with AI extraction.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
                        ),
                        const SizedBox(height: NySpacing.space16),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
                                ),
                                icon: const Icon(Icons.photo_camera_rounded),
                                label: const Text('Take Photo'),
                                onPressed: _pickFromCamera,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
                                ),
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text('Upload File'),
                                onPressed: _pickFromGallery,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: NySpacing.space16),

                        if (_attachedFileName != null) ...[
                          NyCard(
                            backgroundColor: theme.colorScheme.primaryContainer.withAlpha(100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.image_rounded, color: NyColors.accentLight),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _attachedFileName!,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            'Attached & Ready to Sync',
                                            style: TextStyle(fontSize: 11, color: NyColors.statusSuccess, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      onPressed: _removeAttachment,
                                      tooltip: 'Remove',
                                    ),
                                  ],
                                ),
                                if (_attachedFileBytes != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _attachedFileBytes!,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: NySpacing.space16),
                        ],

                        TextField(
                          controller: _textController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notes / Invoice Details (Optional):',
                            hintText: 'e.g., CoolCare AC service invoice received from Ravi.',
                            border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                          ),
                        ),
                        const SizedBox(height: NySpacing.space16),

                        _buildPhoneInputCard(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space12),

            NyButton(
              label: _isUnderstanding ? 'Understanding with AI...' : 'Review Memory Candidate',
              icon: Icons.auto_awesome_rounded,
              isLoading: _isUnderstanding,
              onPressed: _continueWithUnderstanding,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInputCard(ThemeData theme) {
    return NyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: NyColors.statusSuccess),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contact Phone / WhatsApp (Optional):',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Saved so AI can help message this person on WhatsApp when you need service again.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(150)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_rounded, size: 18),
              hintText: 'e.g. +91 98400 12345',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
            ),
          ),
        ],
      ),
    );
  }
}