import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AccountPreferencesScreen extends StatefulWidget {
  const AccountPreferencesScreen({super.key});

  @override
  State<AccountPreferencesScreen> createState() => _AccountPreferencesScreenState();
}

class _AccountPreferencesScreenState extends State<AccountPreferencesScreen> {
  late TextEditingController _geminiKeyController;
  bool _obscureText = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _isFetchingModels = false;
  String? _savedApiKey;
  String? _testResultText;
  bool? _testSuccess;

  List<String> _availableModels = [
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.5-flash',
  ];
  String _selectedModel = 'gemini-3.6-flash';

  @override
  void initState() {
    super.initState();
    _geminiKeyController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    String? foundKey;
    String? foundModel;

    try {
      final json = await ApiService.getSettings();
      final providers = json['aiProviders'] as Map<String, dynamic>?;
      if (providers != null && providers['gemini'] is Map) {
        final gemini = providers['gemini'] as Map<String, dynamic>;
        foundKey = gemini['apiKey'] as String?;
        foundModel = gemini['selectedModel'] as String?;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    setState(() {
      _savedApiKey = foundKey;
      if (foundModel != null && foundModel.isNotEmpty) {
        _selectedModel = foundModel;
      }
      if (foundKey != null && foundKey.isNotEmpty) {
        _geminiKeyController.text = foundKey;
      } else {
        _geminiKeyController.clear();
      }
      _isLoading = false;
    });

    if (foundKey != null && foundKey.isNotEmpty) {
      _fetchSupportedModels(foundKey);
    }
  }

  Future<void> _fetchSupportedModels(String apiKey) async {
    if (apiKey.isEmpty) return;
    setState(() => _isFetchingModels = true);
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final modelsList = json['models'] as List?;
        if (modelsList != null) {
          final List<String> fetched = [];
          for (final m in modelsList) {
            final name = (m['name']?.toString() ?? '').replaceFirst('models/', '');
            final methods = (m['supportedGenerationMethods'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final nameLower = name.toLowerCase();
            final isExcluded = nameLower.contains('preview') ||
                nameLower.contains('image') ||
                nameLower.contains('imagen') ||
                nameLower.contains('vision') ||
                nameLower.contains('audio') ||
                nameLower.contains('video') ||
                nameLower.contains('embed');
            final isGemini3FlashText = nameLower.startsWith('gemini-3.') && nameLower.contains('flash') && !isExcluded;
            if (isGemini3FlashText && methods.contains('generateContent') && name.isNotEmpty) {
              fetched.add(name);
            }
          }
          if (fetched.isNotEmpty) {
            setState(() {
              _availableModels = fetched;
              if (!_availableModels.contains(_selectedModel)) {
                _selectedModel = _availableModels.first;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching models: $e');
    } finally {
      if (mounted) setState(() => _isFetchingModels = false);
    }
  }

  Future<void> _saveSettings() async {
    final newKey = _geminiKeyController.text.trim();
    if (newKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key cannot be empty. Click delete to remove it.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentJson = await ApiService.getSettings();
      final providers = currentJson['aiProviders'] as Map<String, dynamic>? ?? {};
      providers['gemini'] = {
        'apiKey': newKey,
        'selectedModel': _selectedModel,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      currentJson['aiProviders'] = providers;

      final success = await ApiService.saveSettings(currentJson);

      setState(() {
        if (success) _savedApiKey = newKey;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Gemini API key & selected model ($_selectedModel) saved successfully!'
                : 'Failed to save settings to server'),
            backgroundColor: success ? const Color(0xFF00A86B) : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving API Key: $e')),
        );
      }
    }
  }

  Future<void> _deleteSettings() async {
    setState(() => _isSaving = true);
    try {
      final currentJson = await ApiService.getSettings();
      final providers = currentJson['aiProviders'] as Map<String, dynamic>? ?? {};
      providers.remove('gemini');
      currentJson['aiProviders'] = providers;

      await ApiService.saveSettings(currentJson);

      setState(() {
        _savedApiKey = null;
        _geminiKeyController.clear();
        _testResultText = null;
        _testSuccess = null;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini API key deleted.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting key: $e');
      setState(() => _isSaving = false);
    }
  }

  Future<void> _testConnection() async {
    final apiKey = _geminiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key to test.')),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testResultText = null;
      _testSuccess = null;
    });

    String? responseResult;
    bool success = false;
    String lastError = '';

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_selectedModel:generateContent?key=$apiKey');
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "hello"}
            ]
          }
        ]
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final first = candidates.first as Map;
            final content = first['content'] as Map?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = (parts.first as Map)['text']?.toString() ?? '';
              responseResult = '[$_selectedModel]: $text';
              success = true;
            }
          }
          if (!success) {
            responseResult = '[$_selectedModel]: Connected successfully!';
            success = true;
          }
        } catch (_) {
          responseResult = '[$_selectedModel]: Connected (HTTP 200)';
          success = true;
        }
      } else {
        try {
          final errJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errObj = errJson['error'] as Map<String, dynamic>?;
          final msg = errObj?['message']?.toString() ?? response.body;
          lastError = '[$_selectedModel Error]: $msg';
        } catch (_) {
          lastError = '[$_selectedModel Error HTTP ${response.statusCode}]: ${response.body}';
        }
      }
    } catch (e) {
      lastError = '[$_selectedModel Error]: $e';
    }

    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _testSuccess = success;
      _testResultText = success
          ? responseResult
          : (lastError.isNotEmpty ? lastError : 'Connection failed. Please check network and API Key.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF282828);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08);
    final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtextColor = isLight ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

    final bool isConfigured = _savedApiKey != null && _savedApiKey!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 640,
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
                    'Account & Preferences',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: subtextColor),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header banner
                          Text(
                            'AI Provider Settings',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure API key & select model supported by your key for pitch deck generation.',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Gemini AI Provider Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Provider Title & Status Badge Row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1877F2).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        size: 20,
                                        color: Color(0xFF1877F2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI Model Provider',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Active Model: $_selectedModel',
                                          style: const TextStyle(
                                            color: Color(0xFF1877F2),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isConfigured
                                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isConfigured
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isConfigured ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                            size: 12,
                                            color: isConfigured ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isConfigured ? 'Configured' : 'Not Configured',
                                            style: TextStyle(
                                              color: isConfigured ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                Divider(height: 1, color: cardBorder),
                                const SizedBox(height: 16),

                                // API Key Field
                                Text(
                                  'API Key *',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _geminiKeyController,
                                  obscureText: _obscureText,
                                  style: TextStyle(color: textColor, fontSize: 13),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: isLight ? Colors.white : const Color(0xFF282828),
                                    hintText: 'Enter API Key',
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
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 16,
                                        color: subtextColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Preferred Model Selector
                                Row(
                                  children: [
                                    Text(
                                      'Preferred Model *',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_isFetchingModels) ...[
                                      const SizedBox(width: 8),
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1877F2)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isLight ? Colors.white : const Color(0xFF282828),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, boxConstraints) {
                                      final dropdownWidth = boxConstraints.maxWidth;
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Theme(
                                              data: Theme.of(context).copyWith(
                                                hoverColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF333333),
                                              ),
                                              child: PopupMenuButton<String>(
                                                tooltip: 'Select AI Model',
                                                offset: const Offset(0, 36),
                                                elevation: 4,
                                                color: isLight ? Colors.white : const Color(0xFF282828),
                                                shadowColor: Colors.black.withValues(alpha: 0.1),
                                                menuPadding: const EdgeInsets.symmetric(vertical: 4),
                                                constraints: BoxConstraints(minWidth: dropdownWidth - 33, maxWidth: dropdownWidth - 33),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  side: BorderSide(color: cardBorder, width: 1),
                                                ),
                                                onSelected: (val) {
                                                  setState(() {
                                                    _selectedModel = val;
                                                  });
                                                },
                                                itemBuilder: (ctx) {
                                                  return _availableModels.map((m) {
                                                    final isSel = m == _selectedModel;
                                                    return PopupMenuItem<String>(
                                                      value: m,
                                                      height: 30,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            m,
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
                                                  }).toList();
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          _selectedModel,
                                                          style: TextStyle(
                                                            color: textColor,
                                                            fontSize: 12.5,
                                                          ),
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
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 18,
                                            color: cardBorder,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.refresh, size: 14),
                                            tooltip: 'Refresh Supported Models',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: () {
                                              final key = _geminiKeyController.text.trim();
                                              if (key.isNotEmpty) _fetchSupportedModels(key);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Action Buttons (Save / Update / Test / Delete)
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isSaving ? null : _saveSettings,
                                      icon: _isSaving
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.save_outlined, size: 15, color: Colors.white),
                                      label: Text(
                                        isConfigured ? 'Update Settings' : 'Save Settings',
                                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1877F2),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        minimumSize: const Size(80, 34),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isTesting ? null : _testConnection,
                                      icon: _isTesting
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.bolt, size: 15, color: Colors.white),
                                      label: Text(
                                        'Test Key ($_selectedModel)',
                                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7C3AED),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        minimumSize: const Size(80, 34),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    if (isConfigured) ...[
                                      OutlinedButton.icon(
                                        onPressed: _isSaving ? null : _deleteSettings,
                                        icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF4444)),
                                        label: const Text(
                                          'Delete Key',
                                          style: TextStyle(color: Color(0xFFEF4444), fontSize: 12.5),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: isLight ? const Color(0xFFFEF2F2) : const Color(0xFF2A1C1C),
                                          side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          minimumSize: const Size(80, 34),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Test Result Response Drawer Box
                                if (_testResultText != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _testSuccess == true
                                          ? (isLight ? const Color(0xFFF0FDF4) : const Color(0xFF1B2B20))
                                          : (isLight ? const Color(0xFFFEF2F2) : const Color(0xFF2E1B1B)),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _testSuccess == true
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _testSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                                              size: 15,
                                              color: _testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _testSuccess == true ? 'Test Connection Succeeded' : 'Test Connection Result',
                                              style: TextStyle(
                                                color: _testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _testResultText!,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
}
