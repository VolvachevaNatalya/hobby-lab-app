import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'write_review_screen.dart';
import '../routing/transitions.dart';

class ReviewsScreen extends StatefulWidget {
  final String activityName;
  final double rating;
  final int reviewCount;
  final Color colorStart;
  final Color colorEnd;
  final int? organizationId;
  final bool allowWrite;

  const ReviewsScreen({
    super.key,
    required this.activityName,
    required this.rating,
    required this.reviewCount,
    required this.colorStart,
    required this.colorEnd,
    this.organizationId,
    this.allowWrite = false,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = false;
  double _currentRating = 0;
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    _currentCount = widget.reviewCount;
    if (widget.organizationId != null) _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final reviews = await ApiService.getReviews(widget.organizationId!);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        if (reviews.isNotEmpty) {
          _currentCount = reviews.length;
          final sum = reviews.fold<double>(
            0,
            (s, r) => s + ((r['rating'] ?? 0) as num).toDouble(),
          );
          _currentRating = sum / reviews.length;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goWriteReview() async {
    await Navigator.of(context).push(
      modalRoute(builder: (_) => WriteReviewScreen(
        activityName: widget.activityName,
        colorStart: widget.colorStart,
        colorEnd: widget.colorEnd,
        organizationId: widget.organizationId,
      )),
    );
    // Reload after writing a review
    if (widget.organizationId != null && mounted) _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      children: [
                        _buildRatingSummary(),
                        const SizedBox(height: 24),
                        if (_reviews.isEmpty)
                          _buildEmpty()
                        else
                          ..._reviews.map((r) => _ReviewCard(review: r)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.allowWrite ? _buildWriteButton(context) : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.divider),
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
            child: Text(
              AppLocalizations.of(context)!.reviewsTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (widget.allowWrite)
            GestureDetector(
              onTap: _goWriteReview,
              child: ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: Text(
                  AppLocalizations.of(context)!.writeBtn,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: Text(
                  _currentCount > 0 ? _currentRating.toStringAsFixed(1) : '—',
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _stars(_currentCount > 0 ? _currentRating : 0),
              const SizedBox(height: 4),
              Text(
                _currentCount > 0
                    ? AppLocalizations.of(context)!.reviewsCount(_currentCount)
                    : AppLocalizations.of(context)!.noReviewsYetSimple,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noReviewsYetSimple,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.beFirstReview,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteButton(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: GestureDetector(
            onTap: _goWriteReview,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rate_review_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.writeReview,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] ?? 0) as num;
    final comment = (review['comment'] ?? '').toString();
    final l10n = AppLocalizations.of(context)!;
    final reviewerName = (review['reviewer_name'] ?? review['user_name'] ?? l10n.anonymousReviewer).toString();
    final createdAt = review['created_at']?.toString() ?? '';
    final dateStr = createdAt.isNotEmpty
        ? _fmtDate(createdAt)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              _stars(rating.toDouble(), size: 14),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

Widget _stars(double rating, {double size = 16}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final icon = i < rating.floor()
          ? Icons.star_rounded
          : (rating - i >= 0.5)
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded;
      return Icon(icon, color: const Color(0xFFFFD700), size: size);
    }),
  );
}
