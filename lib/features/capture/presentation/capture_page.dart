import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/speech/speech_service.dart';
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
  final _picker = ImagePicker();

  bool _isRecording = false;
  bool _isUnderstanding = false;
  String _liveSpeechStatus = 'Tap the microphone to speak';
  String? _attachedFileName;
  Uint8List? _attachedFileBytes;
  String? _attachedFileBase64;
  String _attachmentType = 'image';

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
            _textController.text = 'Photo Attachment: ${photo.name}';
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
            _textController.text = 'Uploaded Document: ${image.name}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery picker error: $e')),
        );
      }
    }
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
        _liveSpeechStatus = 'Listening to your voice... Speak clearly now.';
      });
      SpeechService.instance.startListening(
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
        : 'Uploaded document: ${_attachedFileName ?? "Document"}';

    setState(() => _isUnderstanding = true);
    try {
      final candidate = await AiGateway.understand(promptToUnderstand);

      final candidateWithAttachment = candidate.copyWith(
        attachmentBase64: _attachedFileBase64,
        attachmentName: _attachedFileName,
        attachmentType: _attachmentType,
      );

      if (mounted) {
        context.push('/understand', extra: candidateWithAttachment);
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
            Tab(icon: Icon(Icons.edit_note), text: 'Text'),
            Tab(icon: Icon(Icons.camera_alt_outlined), text: 'Camera / Scan'),
            Tab(icon: Icon(Icons.mic), text: 'Voice'),
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
                  // Tab 1: Text Capture
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'What would you like to remember?',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Type your note, instruction, or service details. You will review extracted facts before saving.',
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
                            hintText: 'e.g., Doctor John prescribed medication for fever on Aug 20.\nor Suresh serviced my washing machine for ₹1200.',
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tab 2: Camera & File Upload
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Attach Invoices, Bills & Photos',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Capture service bills, appliance model labels, warranties, or receipts directly.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(180)),
                        ),
                        const SizedBox(height: NySpacing.space20),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_camera),
                                label: const Text('Take Photo'),
                                onPressed: _pickFromCamera,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Upload File'),
                                onPressed: _pickFromGallery,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: NySpacing.space20),

                        if (_attachedFileName != null) ...[
                          NyCard(
                            backgroundColor: theme.colorScheme.primaryContainer.withAlpha(80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _attachedFileName!,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            'Attached & Ready to Sync',
                                            style: TextStyle(fontSize: 12, color: NyColors.statusSuccess),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _removeAttachment,
                                      tooltip: 'Remove',
                                    ),
                                  ],
                                ),
                                if (_attachedFileBytes != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
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

                        Text(
                          'Add Notes / Description (Optional):',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.secondary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _textController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Received service invoice from CoolCare.',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: Voice Note with Real Voice Recognition
                  SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          size: 64,
                          color: _isRecording ? NyColors.statusError : theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isRecording ? 'Listening to Your Voice...' : 'Tap to Record Voice Note',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _liveSpeechStatus,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isRecording ? NyColors.statusError : theme.colorScheme.onSurface.withAlpha(180),
                            fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: NySpacing.space20),
                        IconButton.filled(
                          iconSize: 40,
                          onPressed: _toggleVoiceRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          style: IconButton.styleFrom(
                            backgroundColor: _isRecording ? NyColors.statusError : NyColors.primaryLight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(NySpacing.space20),
                          ),
                        ),
                        const SizedBox(height: NySpacing.space20),
                        TextField(
                          controller: _textController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Live Spoken Transcript (Editable):',
                            hintText: 'Speak into your microphone or type instructions here...',
                          ),
                        ),
                      ],
                    ),
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