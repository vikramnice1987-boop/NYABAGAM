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
  String _selectedLanguageCode = 'ta-IN';
  String _liveSpeechStatus = 'Tap microphone and speak';
  String? _attachedFileName;
  Uint8List? _attachedFileBytes;
  String? _attachedFileBase64;
  String _attachmentType = 'image';

  final List<Map<String, String>> _supportedLanguages = [
    {'code': 'ta-IN', 'name': 'à®¤à®®à®¿à®´à¯ (Tamil)'},
    {'code': 'en-IN', 'name': 'English (India)'},
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'hi-IN', 'name': 'à¤¹à¤¿à¤‚à¤¦à¥€ (Hindi)'},
    {'code': 'te-IN', 'name': 'à°¤à±†à°²à±à°—à± (Telugu)'},
    {'code': 'ml-IN', 'name': 'à´®à´²à´¯à´¾à´³à´‚ (Malayalam)'},
    {'code': 'kn-IN', 'name': 'à²•à²¨à³à²¨à²¡ (Kannada)'},
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

  void _toggleVoiceRecording() {
    if (_isRecording) {
      SpeechService.instance.stopListening();
      setState(() {
        _isRecording = false;
        _liveSpeechStatus = 'Recording saved. You can edit the text below.';
      });
    } else {
      setState(() {
        _isRecording = true;
        _liveSpeechStatus = 'Listening in ${_getLanguageName(_selectedLanguageCode)}... Speak clearly now.';
      });
      SpeechService.instance.startListening(
        language: _selectedLanguageCode,
        onResult: (transcript, isFinal) {
          if (mounted && transcript.isNotEmpty) {
            setState(() {
              _textController.text = transcript;
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

  String _getLanguageName(String code) {
    return _supportedLanguages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': code},
    )['name']!;
  }

  void _removeAttachment() {
    setState(() {
      _attachedFileName = null;
      _attachedFileBytes = null;
      _attachedFileBase64 = null;
    });
  }

  Future<void> _continueWithUnderstanding() async {
    final content = _textController.text.trim();
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
        title: const Text('Capture Memory', style: TextStyle(fontWeight: FontWeight.w700)),
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
                Tab(icon: Icon(Icons.mic_rounded, size: 18), text: 'Voice (à®•à¯à®°à®²à¯)'),
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
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type in English, à®¤à®®à®¿à®´à¯, or any language. AI will extract structured facts.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
                        ),
                        const SizedBox(height: NySpacing.space16),

                        TextField(
                          controller: _textController,
                          minLines: 5,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'e.g., Ravi serviced my AC today for â‚¹800.\nor à®°à®µà®¿ à®‡à®©à¯à®±à¯ à®à®šà®¿ à®šà®°à¯à®µà¯€à®¸à¯ à®šà¯†à®¯à¯à®¤à®¾à®°à¯ â‚¹800.',
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
                        NyCard(
                          child: Row(
                            children: [
                              const Icon(Icons.translate_rounded, color: NyColors.accentLight),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Speaking Language:',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _selectedLanguageCode,
                                underline: const SizedBox.shrink(),
                                icon: const Icon(Icons.arrow_drop_down),
                                items: _supportedLanguages.map((lang) {
                                  return DropdownMenuItem<String>(
                                    value: lang['code'],
                                    child: Text(
                                      lang['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedLanguageCode = val;
                                      if (_isRecording) {
                                        _toggleVoiceRecording();
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NySpacing.space20),

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
                          _isRecording ? 'Listening in ${_getLanguageName(_selectedLanguageCode)}...' : 'Tap to Start Speaking',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
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
                            labelText: 'Live Spoken Transcript (Editable):',
                            hintText: 'Speak into your microphone in ${_getLanguageName(_selectedLanguageCode)}...',
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
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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