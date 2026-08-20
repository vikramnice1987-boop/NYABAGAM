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

class _CapturePageState extends State<CapturePage> {
  int _selectedTabIndex = 0; // 0: Text, 1: Voice, 2: Camera
  final _textController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  bool _isRecording = false;
  bool _isUnderstanding = false;
  String _selectedLanguageCode = 'en-IN';
  String _liveSpeechStatus = 'Tap the microphone and start speaking';

  String? _attachedFileName;
  Uint8List? _attachedFileBytes;
  String? _attachedFileBase64;
  String _attachmentType = 'image';

  final List<Map<String, String>> _supportedLanguages = [
    {'code': 'en-IN', 'label': 'English'},
    {'code': 'ta-IN', 'label': 'Tamil'},
    {'code': 'hi-IN', 'label': 'Hindi'},
    {'code': 'te-IN', 'label': 'Telugu'},
    {'code': 'en-US', 'label': 'English (US)'},
  ];

  @override
  void dispose() {
    SpeechService.instance.stopListening();
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

  String _deduplicatePhrases(String input) {
    if (input.trim().isEmpty) return '';
    final words = input.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';

    // Step 1: Remove consecutive identical words
    final dedup = <String>[];
    for (int i = 0; i < words.length; i++) {
      if (dedup.isEmpty || dedup.last.toLowerCase() != words[i].toLowerCase()) {
        dedup.add(words[i]);
      }
    }

    // Step 2: Remove consecutive multi-word repeating phrase blocks (4, 3, 2 words)
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
        _liveSpeechStatus = 'Listening in ${_getLanguageLabel(_selectedLanguageCode)}... Speak clearly now.';
      });
      SpeechService.instance.startListening(
        language: _selectedLanguageCode,
        onResult: (transcript, isFinal) {
          if (mounted && transcript.isNotEmpty) {
            setState(() {
              _textController.text = _deduplicatePhrases(transcript);
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
    final content = _deduplicatePhrases(_textController.text.trim());
    if (content.isEmpty && _attachedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text, speak into the mic, or attach a photo.')),
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
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: 8),
          children: [
            // Custom Segmented Switcher (Text | Voice | Camera)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
              ),
              child: Row(
                children: [
                  _buildTabPill(index: 0, label: 'Text Note', icon: Icons.edit_note_rounded, theme: theme),
                  _buildTabPill(index: 1, label: 'Voice Note', icon: Icons.mic_rounded, theme: theme),
                  _buildTabPill(index: 2, label: 'Scan / Photo', icon: Icons.photo_camera_rounded, theme: theme),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space16),

            // Tab 0: Text Capture
            if (_selectedTabIndex == 0) ...[
              Text(
                'What would you like to remember?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Type in English, Tamil, or any language. AI extracts entities, dates, and amounts.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
              ),
              const SizedBox(height: NySpacing.space16),

              TextField(
                controller: _textController,
                minLines: 4,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText: 'e.g., Ravi serviced my AC today for Rs. 800 and gave 6-month warranty.\nor Dr. Rajesh clinic visit follow up on Aug 25.',
                  border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: NySpacing.space16),

              _buildPhoneInputCard(theme),
            ],

            // Tab 1: Voice Capture
            if (_selectedTabIndex == 1) ...[
              // High-Contrast Custom Language Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, size: 18, color: NyColors.accentLight),
                    const SizedBox(width: 8),
                    const Text(
                      'Speech Language:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _supportedLanguages.map((lang) {
                            final isSel = _selectedLanguageCode == lang['code'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedLanguageCode = lang['code']!;
                                    if (_isRecording) {
                                      _toggleVoiceRecording();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? NyColors.accentLight : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSel ? NyColors.accentLight : theme.colorScheme.outline.withAlpha(80),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSel) ...[
                                        const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        lang['label']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                          color: isSel ? Colors.white : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space20),

              // Glowing Animated Microphone Button
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _toggleVoiceRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(_isRecording ? 28 : 22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? NyColors.statusError : NyColors.accentLight,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? NyColors.statusError : NyColors.accentLight).withAlpha(120),
                              blurRadius: _isRecording ? 32 : 16,
                              spreadRadius: _isRecording ? 8 : 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(160)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space16),

              // Live Transcript Field
              TextField(
                controller: _textController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Live Spoken Transcript (Editable):',
                  hintText: 'Speak clearly into your microphone...',
                  border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: NySpacing.space16),

              _buildPhoneInputCard(theme),
            ],

            // Tab 2: Camera & Scan
            if (_selectedTabIndex == 2) ...[
              Text(
                'Scan Bill, Warranty, or Appliance',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Take a photo of receipt or serial label to preserve with AI entity extraction.',
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
                      label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      label: const Text('Upload File', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: _pickFromGallery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NySpacing.space16),

              if (_attachedFileName != null) ...[
                NyCard(
                  backgroundColor: theme.colorScheme.primaryContainer.withAlpha(90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.image_rounded, color: NyColors.accentLight),
                          const SizedBox(width: 10),
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
                                  'Attached & Verified',
                                  style: TextStyle(fontSize: 11, color: NyColors.statusSuccess, fontWeight: FontWeight.w700),
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
                        const SizedBox(height: 10),
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
                  labelText: 'Invoice / Warranty Note (Optional):',
                  hintText: 'e.g., CoolCare AC service invoice received from Ravi.',
                  border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: NySpacing.space16),

              _buildPhoneInputCard(theme),
            ],

            const SizedBox(height: NySpacing.space20),

            // Primary Action Button (Review Memory Candidate)
            NyButton(
              label: _isUnderstanding ? 'Understanding with AI...' : 'Review Memory Candidate',
              icon: Icons.auto_awesome_rounded,
              isLoading: _isUnderstanding,
              onPressed: _continueWithUnderstanding,
            ),

            // Bottom Safe Area Spacing to prevent overlap with Netlify / mobile navigation bars
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({
    required int index,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isRecording) {
            SpeechService.instance.stopListening();
            _isRecording = false;
          }
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withAlpha(180),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11,
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
              ),
            ],
          ),
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
                  'WhatsApp / Contact Number (Optional):',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Saved so AI can help message this contact on WhatsApp when service is needed.',
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