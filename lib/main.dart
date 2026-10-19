import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'image_helper.dart';
import 'presentation_editor_screen.dart';
import 'account_preferences_screen.dart';
import 'create_presentation_screen.dart';
import 'slides/slides.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BrowserContextMenu.disableContextMenu();
  initSlideRegistry();
  runApp(const PresentationApp());
}


class PresentationApp extends StatelessWidget {
  const PresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeyDoc Outreach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Satoshi',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1877F2),
          surface: Color(0xFFFFFFFF),
        ),
      ),
      home: const PresentationHomeScreen(),
    );
  }
}

class PresentationModel {
  final String id;
  final String companyName;
  final String sector;
  final Color primaryColor;
  final Color accentColor;
  final int slideCount;
  final String firstSlideTitle;
  final String folderPath;
  final String logoPath;
  final Map<String, dynamic>? rawManifest;
  final Map<String, dynamic>? rawPresentation;

  PresentationModel({
    required this.id,
    required this.companyName,
    required this.sector,
    required this.primaryColor,
    required this.accentColor,
    required this.slideCount,
    required this.firstSlideTitle,
    required this.folderPath,
    this.logoPath = '',
    this.rawManifest,
    this.rawPresentation,
  });

  PresentationModel copyWith({
    String? id,
    String? companyName,
    String? sector,
    Color? primaryColor,
    Color? accentColor,
    int? slideCount,
    String? firstSlideTitle,
    String? folderPath,
    String? logoPath,
    Map<String, dynamic>? rawManifest,
    Map<String, dynamic>? rawPresentation,
  }) {
    return PresentationModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      sector: sector ?? this.sector,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      slideCount: slideCount ?? this.slideCount,
      firstSlideTitle: firstSlideTitle ?? this.firstSlideTitle,
      folderPath: folderPath ?? this.folderPath,
      logoPath: logoPath ?? this.logoPath,
      rawManifest: rawManifest ?? this.rawManifest,
      rawPresentation: rawPresentation ?? this.rawPresentation,
    );
  }
}

class PresentationHomeScreen extends StatefulWidget {
  const PresentationHomeScreen({super.key});

  @override
  State<PresentationHomeScreen> createState() => _PresentationHomeScreenState();
}

class _PresentationHomeScreenState extends State<PresentationHomeScreen> {
  List<PresentationModel> _presentations = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _hoveredIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPresentations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PresentationModel> get _filteredPresentations {
    if (_searchQuery.isEmpty) return _presentations;
    final q = _searchQuery.toLowerCase();
    return _presentations.where((p) {
      return p.companyName.toLowerCase().contains(q) ||
          p.sector.toLowerCase().contains(q) ||
          p.firstSlideTitle.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
    }).toList();
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

  /// Main method to load presentations from backend server
  Future<void> _loadPresentations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final List<PresentationModel> loaded = [];

    try {
      final serverPresentations = await ApiService.getPresentations();

      for (final pMap in serverPresentations) {
        final id = pMap['id']?.toString() ?? '';
        final folderPath = pMap['folderPath']?.toString() ?? id;
        final manifestJson = Map<String, dynamic>.from(pMap['manifest'] as Map? ?? {});
        final presJson = Map<String, dynamic>.from(pMap['presentation'] as Map? ?? {});

        String companyName = '';
        String sector = manifestJson['sector'] as String? ?? '';

        final companyVal = manifestJson['company'];
        if (companyVal is String) {
          companyName = companyVal;
        } else if (companyVal is Map<String, dynamic>) {
          companyName = companyVal['name'] as String? ?? '';
          if (sector.isEmpty) {
            sector = companyVal['sector'] as String? ?? '';
          }
        }

        Color primaryColor = const Color(0xFF123456);
        Color accentColor = const Color(0xFF00A86B);
        String logoPath = '';

        final theme = manifestJson['theme'] as Map<String, dynamic>?;
        if (theme != null) {
          if (theme['accent'] != null) {
            accentColor = _parseColor(theme['accent'].toString(), fallback: accentColor);
          } else if (theme['colors'] is Map) {
            final colors = theme['colors'] as Map<String, dynamic>;
            if (colors['accent'] != null) {
              accentColor = _parseColor(colors['accent'].toString(), fallback: accentColor);
            } else if (colors['primary'] != null) {
              accentColor = _parseColor(colors['primary'].toString(), fallback: accentColor);
            }
          }
          if (theme['logo'] != null && theme['logo'].toString().isNotEmpty) {
            logoPath = theme['logo'].toString();
          }
        }
        if (logoPath.isEmpty && manifestJson['logo'] != null) {
          logoPath = manifestJson['logo'].toString();
        }
        if (logoPath.isEmpty && manifestJson['companyLogo'] != null) {
          logoPath = manifestJson['companyLogo'].toString();
        }
        if (logoPath.isEmpty && manifestJson['sourceContext'] is Map && (manifestJson['sourceContext'] as Map)['companyLogo'] != null) {
          logoPath = (manifestJson['sourceContext'] as Map)['companyLogo'].toString();
        }

        final slides = presJson['slides'] as List<dynamic>? ?? [];
        final slideCount = slides.length;
        String firstSlideTitle = '';
        if (slides.isNotEmpty && slides.first is Map) {
          final firstContent = (slides.first as Map)['content'] as Map<String, dynamic>?;
          if (firstContent != null) {
            firstSlideTitle = firstContent['title'] as String? ?? '';
          }
        }

        loaded.add(PresentationModel(
          id: id,
          companyName: companyName.isNotEmpty ? companyName : id,
          sector: sector,
          primaryColor: primaryColor,
          accentColor: accentColor,
          slideCount: slideCount,
          firstSlideTitle: firstSlideTitle,
          folderPath: folderPath,
          logoPath: logoPath,
          rawManifest: manifestJson,
          rawPresentation: presJson,
        ));
      }
    } catch (e, stack) {
      debugPrint('Error loading presentations from server: $e\n$stack');
      _errorMessage = e.toString();
      if (mounted) {
        _showErrorDialog('Presentation Load Error', 'Error loading presentations from server:\n\n$e');
      }
    }

    setState(() {
      _presentations = loaded;
      _isLoading = false;
    });
  }

  Color _parseColor(String hex, {required Color fallback}) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF292929),
      body: Column(
        children: [
          // Top Navigation Capsule Bar Header
          _buildHeaderBar(),

          // Main Workspace Grid displaying Presentations
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPresentationsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationsGrid() {
    if (_presentations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No presentations found in HeyDoc Outreach server storage.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadPresentations,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Presentations'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Debug: $_errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }

    final filtered = _filteredPresentations;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No presentations match "$_searchQuery"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Search Filter'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 5;
          if (constraints.maxWidth < 600) {
            crossAxisCount = 1;
          } else if (constraints.maxWidth < 900) {
            crossAxisCount = 2;
          } else if (constraints.maxWidth < 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth < 1500) {
            crossAxisCount = 4;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14.0,
              mainAxisSpacing: 14.0,
              childAspectRatio: 1.25,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildPresentationCard(index, filtered[index]);
            },
          );
        },
      ),
    );
  }

  /// Top Capsule Header Bar matching screenshot design
  Widget _buildHeaderBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final capsuleColor = isLight ? Colors.white : const Color(0xFF383838);
    final capsuleBorderColor = isLight ? const Color(0xFFE5E7EB) : Colors.white.withValues(alpha: 0.05);
    final textColor = isLight ? const Color(0xFF1F2937) : const Color(0xFFE0E0E0);
    final hintColor = isLight ? const Color(0xFF9CA3AF) : const Color(0xFF888888);

    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 12.0),
      color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF292929),
      child: Row(
        children: [
          // Left Capsule: "Create new slide" (or presentation)
          InkWell(
            onTap: () async {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const CreatePresentationScreen(),
              );
              _loadPresentations();
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              decoration: BoxDecoration(
                color: capsuleColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: capsuleBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    size: 17,
                    color: textColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Create new slide',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Center Capsule: Working Search Bar
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: capsuleColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: capsuleBorderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: hintColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                        });
                      },
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search presentations by name, sector, title...',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(Icons.cancel, size: 16, color: hintColor),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Right Capsule: Settings Dropdown Menu
          PopupMenuButton<String>(
            tooltip: 'Settings',
            color: Colors.white,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            surfaceTintColor: Colors.transparent,
            menuPadding: const EdgeInsets.symmetric(vertical: 4),
            constraints: const BoxConstraints(minWidth: 175, maxWidth: 200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            offset: const Offset(0, 46),
            onSelected: (value) {
              if (value == 'account') {
                showDialog(
                  context: context,
                  builder: (_) => const AccountPreferencesScreen(),
                );
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'account',
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: const [
                      Icon(Icons.person_outline, size: 15, color: Color(0xFF374151)),
                      SizedBox(width: 8),
                      Text(
                        'Account & Preferences',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              height: 42,
              padding: const EdgeInsets.only(left: 8.0, right: 14.0),
              decoration: BoxDecoration(
                color: capsuleColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: capsuleBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1877F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.settings_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: hintColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresentationContextMenu(Offset globalPosition, PresentationModel presentation) async {
    final RelativeRect position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx + 1,
      globalPosition.dy + 1,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'open',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 15, color: Color(0xFF374151)),
              SizedBox(width: 8),
              Text(
                'Open Presentation',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF1F2937), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: const [
              Icon(Icons.copy_outlined, size: 15, color: Color(0xFF374151)),
              SizedBox(width: 8),
              Text(
                'Duplicate Presentation',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF1F2937), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'rename',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: const [
              Icon(Icons.drive_file_rename_outline, size: 15, color: Color(0xFF374151)),
              SizedBox(width: 8),
              Text(
                'Rename Presentation',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF1F2937), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text(
                'Delete Presentation',
                style: TextStyle(fontSize: 12.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted) return;

    if (selected == 'open') {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PresentationEditorScreen(presentation: presentation),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (mounted) {
        _loadPresentations();
      }
    } else if (selected == 'duplicate') {
      _duplicatePresentation(presentation);
    } else if (selected == 'rename') {
      _renamePresentation(presentation);
    } else if (selected == 'delete') {
      _confirmAndDeletePresentation(presentation);
    }
  }

  void _duplicatePresentation(PresentationModel presentation) async {
    try {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final Map<String, dynamic> newManifest = Map<String, dynamic>.from(presentation.rawManifest ?? {});
      final Map<String, dynamic> newPresentationMap = Map<String, dynamic>.from(presentation.rawPresentation ?? {});

      // Use duplication time as new ID instead of copying original's creation time ID
      newManifest['id'] = newId;
      newManifest['createdAt'] = newId;
      newManifest['updatedAt'] = newId;

      // Add " Copy" suffix to the presentation company name
      final String originalName = presentation.companyName;
      final String newCompanyName = '$originalName Copy';

      if (newManifest['company'] is Map) {
        final compMap = Map<String, dynamic>.from(newManifest['company'] as Map);
        compMap['name'] = newCompanyName;
        newManifest['company'] = compMap;
      } else {
        newManifest['company'] = newCompanyName;
      }
      if (newManifest.containsKey('companyName')) {
        newManifest['companyName'] = newCompanyName;
      }

      final result = await ApiService.createPresentation(
        id: newId,
        manifest: newManifest,
        presentation: newPresentationMap,
        sourceId: presentation.id,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Duplicated presentation as "$newCompanyName" ($newId)'),
              backgroundColor: const Color(0xFF00A86B),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to duplicate presentation'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        _loadPresentations();
      }
    } catch (e) {
      debugPrint('Error duplicating presentation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating presentation: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _renamePresentation(PresentationModel presentation) async {
    final controller = TextEditingController(text: presentation.companyName);

    final String? newName = await showDialog<String>(
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
        title: const Text(
          'Rename Presentation',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter new name for "${presentation.companyName}":',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                hintText: 'Presentation Name',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF1877F2)),
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.of(ctx).pop(val.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(ctx).pop(trimmed);
              }
            },
            child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName != null && newName.isNotEmpty && newName != presentation.companyName) {
      try {
        final serverPresentations = await ApiService.getPresentations();
        final pMap = serverPresentations.firstWhere(
          (p) => p['id']?.toString() == presentation.id,
          orElse: () => <String, dynamic>{},
        );

        final manifest = Map<String, dynamic>.from(pMap['manifest'] as Map? ?? {});
        manifest['company'] = newName;
        manifest['name'] = '$newName Pitch';
        manifest['updatedAt'] = DateTime.now().toUtc().toIso8601String();

        final success = await ApiService.savePresentation(
          id: presentation.id,
          manifest: manifest,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Presentation renamed to "$newName"'),
                backgroundColor: const Color(0xFF00A86B),
              ),
            );
            _loadPresentations();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to rename presentation on server'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error renaming presentation: $e');
      }
    }
  }

  void _confirmAndDeletePresentation(PresentationModel presentation) async {
    final bool? confirm = await showDialog<bool>(
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
        title: const Text(
          'Delete Presentation',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        content: Text(
          'Are you sure you want to delete "${presentation.companyName}" (${presentation.id})?\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await ApiService.deletePresentation(presentation.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Deleted presentation ${presentation.id}'
                  : 'Failed to delete presentation ${presentation.id}'),
              backgroundColor: success ? Colors.black87 : Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        _loadPresentations();
      } catch (e) {
        debugPrint('Error deleting presentation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete presentation: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  /// Individual Presentation Card tile
  Widget _buildPresentationCard(int index, PresentationModel presentation) {
    final bool isHovered = _hoveredIndex == index;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => PresentationEditorScreen(presentation: presentation),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          _loadPresentations();
        },
        onSecondaryTapUp: (details) {
          _showPresentationContextMenu(details.globalPosition, presentation);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF363636),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isHovered
                  ? (isLight ? const Color(0xFF9CA3AF) : const Color(0xFF555555))
                  : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF424242)),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? Colors.black.withValues(alpha: isHovered ? 0.08 : 0.04)
                    : Colors.black.withValues(alpha: isHovered ? 0.4 : 0.25),
                blurRadius: isHovered ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: Column(
              children: [
                // Upper Presentation Thumbnail/Preview Area (72% height)
                Expanded(
                  flex: 72,
                  child: Container(
                    width: double.infinity,
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF444444),
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.center,
                    child: presentation.logoPath.isNotEmpty
                        ? Container(
                            height: 54,
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: buildUniversalImage(
                              presentation.logoPath,
                              presentationId: presentation.id,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Text(
                            presentation.companyName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF111827) : const Color(0xFFE0E0E0),
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Lower Presentation Details Footer Strip (30% height)
                Expanded(
                  flex: 30,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF333333),
                      border: Border(
                        top: BorderSide(
                          color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF2C2C2C),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                presentation.companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF111827) : const Color(0xFFE0E0E0),
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${presentation.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF6B7280) : const Color(0xFF888888),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${presentation.slideCount} ${presentation.slideCount == 1 ? 'slide' : 'slides'}',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF4B5563) : const Color(0xFFA0A0A0),
                              fontSize: 9.5,
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
        ),
      ),
    );
  }
}
