import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_category.dart';
import '../models/app_class.dart';
import '../services/api_service.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedCategory = 'All';
  final _sheetController = DraggableScrollableController();
  List<String> _categoryNames = ['All'];
  List<AppClass> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getClasses(),
      ]);
      if (mounted) {
        setState(() {
          final cats = results[0] as List<AppCategory>;
          _categoryNames = ['All', ...cats.map((c) => c.name)];
          _classes = results[1] as List<AppClass>;
        });
      }
    } catch (_) {}
  }

  List<AppClass> get _filteredClasses {
    if (_selectedCategory == 'All') return _classes;
    return _classes
        .where((c) =>
            c.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Full-screen map placeholder ──
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter()),
          ),
          // ── User location dot ──
          Positioned.fill(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned(
                    left: 0.5 * w - 10,
                    top: 0.52 * h - 10,
                    child: _UserDot(),
                  ),
                ],
              );
            }),
          ),
          // ── Top overlay: header + category chips ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildCategoryChips(),
                ],
              ),
            ),
          ),
          // ── Bottom sheet ──
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.70,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredClasses.length} Activities',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _selectedCategory == 'All'
                                ? 'All categories'
                                : _selectedCategory,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _filteredClasses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: AppColors.divider),
                                    ),
                                    child: const Icon(Icons.map_outlined,
                                        size: 30, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No activities found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: _filteredClasses.length,
                              itemBuilder: (_, i) {
                                final cls = _filteredClasses[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: AppColors.divider),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.purple
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                            Icons.school_rounded,
                                            color: AppColors.purple,
                                            size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cls.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              cls.organizationName.isNotEmpty
                                                  ? cls.organizationName
                                                  : cls.category,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.divider),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.divider),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Nearby Activities',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.divider),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.my_location_rounded,
                color: AppColors.purple, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categoryNames.length,
        itemBuilder: (_, i) {
          final cat = _categoryNames[i];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.brandGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : AppColors.divider,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Map painter ──────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1A1F2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final blockPaint = Paint()..color = const Color(0xFF252B3B);
    final roadPaint = Paint()
      ..color = const Color(0xFF2D3347)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final mainRoadPaint = Paint()
      ..color = const Color(0xFF343D52)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    final parkPaint = Paint()..color = const Color(0xFF1A2E20);

    final rng = math.Random(42);
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 5; col++) {
        final bw = 60.0 + rng.nextDouble() * 40;
        final bh = 50.0 + rng.nextDouble() * 30;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col * 80.0 + rng.nextDouble() * 10,
              row * 70.0 + rng.nextDouble() * 10,
              bw,
              bh,
            ),
            const Radius.circular(4),
          ),
          blockPaint,
        );
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.55, 120, 80),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    final roads = [
      [Offset(0, size.height * 0.33), Offset(size.width, size.height * 0.33)],
      [Offset(0, size.height * 0.60), Offset(size.width, size.height * 0.60)],
      [Offset(size.width * 0.30, 0), Offset(size.width * 0.30, size.height)],
      [Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height)],
    ];
    for (final r in roads) {
      canvas.drawLine(r[0], r[1], mainRoadPaint);
    }

    final secondary = [
      [Offset(0, size.height * 0.18), Offset(size.width, size.height * 0.18)],
      [Offset(0, size.height * 0.48), Offset(size.width, size.height * 0.48)],
      [Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75)],
      [Offset(size.width * 0.15, 0), Offset(size.width * 0.15, size.height)],
      [Offset(size.width * 0.48, 0), Offset(size.width * 0.48, size.height)],
      [Offset(size.width * 0.82, 0), Offset(size.width * 0.82, size.height)],
    ];
    for (final r in secondary) {
      canvas.drawLine(r[0], r[1], roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── User location dot ────────────────────────────────────────────────────────

class _UserDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3B82F6),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
