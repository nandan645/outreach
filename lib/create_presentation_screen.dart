import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'image_helper.dart';
import 'main.dart';
import 'presentation_editor_screen.dart';

class CreatePresentationScreen extends StatefulWidget {
  const CreatePresentationScreen({super.key});

  @override
  State<CreatePresentationScreen> createState() => _CreatePresentationScreenState();
}

class _CreatePresentationScreenState extends State<CreatePresentationScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  String _selectedSector = 'Labs & Diagnostics';

  String? _uploadedPdfName;
  Uint8List? _uploadedPdfBytes;
  int? _uploadedPdfSizeBytes;

  String? _uploadedLogoName;
  String? _uploadedLogoPath;
  Uint8List? _uploadedLogoBytes;

  bool _isGenerating = false;
  String _generationStatus = '';

  final List<String> _sectors = [
    'Labs & Diagnostics',
    'Hospital Care',
    'Health Insurance',
    'E-Pharmacies',
    'Digital Health & Fitness',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  // Select PDF file using FilePicker
  Future<void> _selectPdfDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        dialogTitle: 'Select PDF Document',
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        final size = bytes.length;
        setState(() {
          _uploadedPdfName = file.name;
          _uploadedPdfBytes = bytes;
          _uploadedPdfSizeBytes = size;
        });
      }
    } catch (e) {
      debugPrint('Error picking PDF file: $e');
    }
  }

  void _removePdfDocument() {
    setState(() {
      _uploadedPdfName = null;
      _uploadedPdfBytes = null;
      _uploadedPdfSizeBytes = null;
    });
  }

  // Select Logo image using ImageSelectionDialog (opens directly in Logo Presets tab)
  Future<void> _selectLogoImage() async {
    showDialog(
      context: context,
      builder: (dialogCtx) => ImageSelectionDialog(
        currentPath: _uploadedLogoPath,
        companyName: _companyNameController.text.trim(),
        initialTabIndex: 1, // Directly land on Logo Presets tab
        onPresetSelected: (presetAssetPath) {
          Navigator.of(dialogCtx).pop();
          setState(() {
            _uploadedLogoName = presetAssetPath.split('/').last;
            _uploadedLogoPath = presetAssetPath;
            _uploadedLogoBytes = null;
          });
        },
        onCustomUpload: () async {
          Navigator.of(dialogCtx).pop();
          try {
            final files = await FilePicker.pickFiles(
              type: FileType.image,
              dialogTitle: 'Select Company Logo Image',
            );
            if (files.isNotEmpty) {
              final file = files.first;
              final bytes = await file.readAsBytes();
              setState(() {
                _uploadedLogoName = file.name;
                _uploadedLogoPath = file.name;
                _uploadedLogoBytes = bytes;
              });
            }
          } catch (e) {
            debugPrint('Error picking Logo file: $e');
          }
        },
        onClearImage: () {
          Navigator.of(dialogCtx).pop();
          _removeLogoImage();
        },
      ),
    );
  }

  void _removeLogoImage() {
    setState(() {
      _uploadedLogoName = null;
      _uploadedLogoPath = null;
      _uploadedLogoBytes = null;
    });
  }



  String _getPromptFileNameForSector(String sector) {
    switch (sector) {
      case 'Digital Health & Fitness':
        return 'digital_health_and_fitness.md';
      case 'E-Pharmacies':
        return 'e-pharmacies.md';
      case 'Health Insurance':
        return 'health_insurance.md';
      case 'Hospital Care':
        return 'hospital_care.md';
      case 'Labs & Diagnostics':
      case 'Labs and Diagnostics':
      default:
        return 'labs_and_diagnostics.md';
    }
  }

  Future<String> _extractPdfText(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      return '';
    }
    String pdfStr;
    try {
      pdfStr = utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      pdfStr = latin1.decode(bytes, allowInvalid: true);
    }
    final buffer = StringBuffer();
    final regExp = RegExp(r'[\x20-\x7E\t\r\n]{4,}');
    final matches = regExp.allMatches(pdfStr);
    for (final match in matches) {
      final str = match.group(0)!;
      if (!str.contains('obj') &&
          !str.contains('endobj') &&
          !str.contains('stream') &&
          !str.contains('xref') &&
          !str.contains('Catalog') &&
          !str.contains('Font')) {
        buffer.writeln(str);
      }
    }
    final txt = buffer.toString().trim();
    if (txt.length < 20) {
      return 'PDF source document uploaded: ${_uploadedPdfName ?? "Document"}';
    }
    return txt;
  }

  Future<String> _loadSectorPrompt(String sector) async {
    final fileName = _getPromptFileNameForSector(sector);
    return await rootBundle.loadString('assets/prompts/$fileName');
  }

  Future<Map<String, String>> _getGeminiConfig() async {
    try {
      final json = await ApiService.getSettings();
      final providers = json['aiProviders'] as Map<String, dynamic>?;
      final gemini = providers?['gemini'] as Map<String, dynamic>?;
      final key = gemini?['apiKey'] as String?;
      final model = gemini?['selectedModel'] as String? ?? 'gemini-3.6-flash';
      if (key != null && key.isNotEmpty) {
        return {'apiKey': key, 'selectedModel': model};
      }
    } catch (e) {
      debugPrint('Error getting saved Gemini config: $e');
    }
    return {};
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
          ],
        ),
        content: SelectableText(message, style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePitchDeck() async {
    final config = await _getGeminiConfig();
    final apiKey = config['apiKey'];
    final preferredModel = config['selectedModel'] ?? 'gemini-3.6-flash';

    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        _showErrorDialog(
          'Missing Gemini API Key',
          'No Gemini API Key found. Please configure your API Key in Account & Preferences.',
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationStatus = 'Loading sector prompt template ($_selectedSector)...';
    });

    try {
      final promptContent = await _loadSectorPrompt(_selectedSector);

      setState(() => _generationStatus = 'Extracting document insights from PDF...');
      final pdfText = await _extractPdfText(_uploadedPdfBytes);

      final fullPrompt = '$promptContent\n\n'
          '==================================================\n'
          'METADATA FOR THIS PRESENTATION\n'
          '==================================================\n'
          'Company Name: ${_companyNameController.text.trim()}\n'
          'Sector: $_selectedSector\n'
          'Theme Color: #00A86B\n\n'
          '==================================================\n'
          'SOURCE DOCUMENT CONTENT\n'
          '==================================================\n'
          '$pdfText\n\n'
          '==================================================\n'
          'IMPORTANT INSTRUCTION:\n'
          'Respond strictly with valid JSON only. Do not wrap in markdown ```json formatting. The root object must contain "slides" array with the 15 required slide objects.\n'
          '==================================================';

      setState(() => _generationStatus = 'Generating 15 pitch deck slides with $preferredModel...\nThis may take 1-2 minutes for detailed slide content.');

      String rawText = '';
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$preferredModel:generateContent?key=$apiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": fullPrompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 180));

      if (res.statusCode == 200) {
        final resJson = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final candidates = resJson['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCand = candidates.first as Map;
          final contentObj = firstCand['content'] as Map?;
          final partsList = contentObj?['parts'] as List?;
          rawText = (partsList?.first as Map?)?['text']?.toString() ?? '';
        }
      } else {
        throw Exception('Gemini API error ($preferredModel HTTP ${res.statusCode}): ${utf8.decode(res.bodyBytes)}');
      }

      if (rawText.isEmpty) {
        throw Exception('Received empty response text from Gemini API ($preferredModel).');
      }

      rawText = rawText.trim();
      if (rawText.startsWith('```json')) {
        rawText = rawText.replaceFirst('```json', '');
        if (rawText.endsWith('```')) {
          rawText = rawText.substring(0, rawText.length - 3);
        }
      } else if (rawText.startsWith('```')) {
        rawText = rawText.replaceFirst('```', '');
        if (rawText.endsWith('```')) {
          rawText = rawText.substring(0, rawText.length - 3);
        }
      }
      rawText = rawText.trim();

      final parsedJson = jsonDecode(rawText) as Map<String, dynamic>;

      setState(() => _generationStatus = 'Saving generated presentation files...');
      final String presentationId = await _createPresentationFiles(
        parsedJson,
        pdfText: pdfText,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully created pitch deck for ${_companyNameController.text.trim()} ($presentationId)!'),
          backgroundColor: const Color(0xFF00A86B),
        ),
      );

      final presModel = PresentationModel(
        id: presentationId,
        companyName: _companyNameController.text.trim(),
        sector: _selectedSector,
        primaryColor: const Color(0xFF123456),
        accentColor: const Color(0xFF00A86B),
        slideCount: (parsedJson['slides'] as List?)?.length ?? 15,
        firstSlideTitle: _companyNameController.text.trim(),
        folderPath: presentationId,
        logoPath: _uploadedLogoPath ?? '',
      );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PresentationEditorScreen(presentation: presModel),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e, stack) {
      debugPrint('Error generating pitch deck: $e\n$stack');
      if (mounted) {
        setState(() => _isGenerating = false);
        _showErrorDialog(
          'Pitch Deck Generation Failed',
          'An error occurred while generating the pitch deck using Gemini API:\n\n$e',
        );
      }
    }
  }

  Future<String> _createPresentationFiles(
    Map<String, dynamic> presentationMap, {
    required String pdfText,
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    String? logoRelativePath;
    if (_uploadedLogoBytes != null && _uploadedLogoName != null) {
      final uploadResult = await ApiService.uploadFile(
        presentationId: newId,
        filename: _uploadedLogoName!,
        bytes: _uploadedLogoBytes!,
      );
      if (uploadResult != null) {
        logoRelativePath = uploadResult['relativePath'] as String?;
      }
    } else if (_uploadedLogoPath != null && _uploadedLogoPath!.isNotEmpty) {
      logoRelativePath = _uploadedLogoPath;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();

    final manifestContent = {
      "id": newId,
      "name": "${_companyNameController.text.trim()} Pitch",
      "company": _companyNameController.text.trim(),
      "sector": _selectedSector,
      "theme": {
        "accent": "#00A86B",
        if (logoRelativePath != null && logoRelativePath.isNotEmpty)
          "logo": logoRelativePath
      },
      "sourceContext": {
        "pdfName": _uploadedPdfName ?? '',
        "pdfText": pdfText,
        "sector": _selectedSector,
        "company": _companyNameController.text.trim(),
      },
      "createdAt": nowIso,
      "updatedAt": nowIso
    };

    await ApiService.createPresentation(
      id: newId,
      manifest: manifestContent,
      presentation: presentationMap,
    );

    return newId;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF282828);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08);
    final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtextColor = isLight ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    'Create New Pitch Deck',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: subtextColor),
                    onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload your company PDF document and configure metadata to generate a tailored 15-slide presentation.',
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // 1. Company Name Field
                    Text(
                      'Company Name *',
                      style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _companyNameController,
                      enabled: !_isGenerating,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E1E1E),
                        hintText: 'Enter company or organization name (e.g. Acme Health)',
                        hintStyle: TextStyle(color: subtextColor, fontSize: 12.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF1877F2), width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Sector Field
                    Text(
                      'Industry Sector *',
                      style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cardBorder),
                      ),
                      child: LayoutBuilder(
                        builder: (context, boxConstraints) {
                          final dropdownWidth = boxConstraints.maxWidth;
                          return Theme(
                            data: Theme.of(context).copyWith(
                              hoverColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF333333),
                            ),
                            child: PopupMenuButton<String>(
                              enabled: !_isGenerating,
                              tooltip: 'Select Sector',
                              offset: const Offset(0, 36),
                              elevation: 4,
                              color: isLight ? Colors.white : const Color(0xFF282828),
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              menuPadding: const EdgeInsets.symmetric(vertical: 4),
                              constraints: BoxConstraints(minWidth: dropdownWidth, maxWidth: dropdownWidth),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: cardBorder, width: 1),
                              ),
                              onSelected: (val) => setState(() => _selectedSector = val),
                              itemBuilder: (ctx) => _sectors.map((sec) {
                                final isSel = sec == _selectedSector;
                                return PopupMenuItem<String>(
                                  value: sec,
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    children: [
                                      Text(
                                        sec,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSel
                                              ? const Color(0xFF1877F2)
                                              : (isLight ? const Color(0xFF1F2937) : Colors.white),
                                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isSel)
                                        const Icon(Icons.check, size: 14, color: Color(0xFF1877F2)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedSector,
                                        style: TextStyle(color: textColor, fontSize: 12.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.unfold_more,
                                      size: 14,
                                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Logo Upload/Selection Field
                    Row(
                      children: [
                        Text(
                          'Company Logo',
                          style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(Optional)',
                          style: TextStyle(color: subtextColor, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildLogoUploadWidget(isLight, textColor, subtextColor, cardBorder),

                    const SizedBox(height: 16),

                    // 4. PDF Document Upload Field
                    Row(
                      children: [
                        Text(
                          'Source Document (PDF)',
                          style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(Optional - improves slide accuracy)',
                          style: TextStyle(color: subtextColor, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildPdfUploadWidget(isLight, textColor, subtextColor, cardBorder),

                    const SizedBox(height: 24),

                    // Progress Status Indicator during generation
                    if (_isGenerating) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF0F9FF) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1877F2).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1877F2)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _generationStatus,
                                style: const TextStyle(color: Color(0xFF1877F2), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Generate Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: (_isGenerating || _companyNameController.text.trim().isEmpty)
                            ? null
                            : _generatePitchDeck,
                        icon: _isGenerating
                            ? const SizedBox.shrink()
                            : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                        label: Text(
                          _isGenerating ? 'Generating Pitch Deck...' : 'Generate Pitch Deck',
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          disabledBackgroundColor: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfUploadWidget(bool isLight, Color textColor, Color subtextColor, Color cardBorder) {
    if (_uploadedPdfName == null) {
      return InkWell(
        onTap: _isGenerating ? null : _selectPdfDocument,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cardBorder, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 32, color: Color(0xFF1877F2)),
              const SizedBox(height: 8),
              Text(
                'Click to browse and upload PDF document',
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Supports company profiles, brochures, product specs (PDF format)',
                style: TextStyle(color: subtextColor, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final kb = ((_uploadedPdfSizeBytes ?? 0) / 1024).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF0FDF4) : const Color(0xFF1B2B20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00A86B).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Color(0xFF00A86B), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _uploadedPdfName!,
                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (kb > 0)
                  Text(
                    '$kb KB',
                    style: TextStyle(color: subtextColor, fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
            tooltip: 'Remove PDF',
            onPressed: _isGenerating ? null : _removePdfDocument,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoUploadWidget(bool isLight, Color textColor, Color subtextColor, Color cardBorder) {
    if (_uploadedLogoPath == null && _uploadedLogoBytes == null) {
      return InkWell(
        onTap: _isGenerating ? null : _selectLogoImage,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 34,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.image_outlined, size: 15, color: Color(0xFF1877F2)),
              const SizedBox(width: 8),
              Text(
                'Select Logo Image or Preset',
                style: TextStyle(
                  color: isLight ? const Color(0xFF1F2937) : Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _uploadedLogoBytes != null
                ? Image.memory(
                    _uploadedLogoBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.image, size: 20, color: Colors.grey),
                  )
                : buildUniversalImage(
                    _uploadedLogoPath!,
                    fit: BoxFit.contain,
                    fallback: const Icon(Icons.image, size: 20, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _uploadedLogoName ?? 'Company Logo Loaded',
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
            tooltip: 'Remove Logo',
            onPressed: _isGenerating ? null : _removeLogoImage,
          ),
        ],
      ),
    );
  }
}
