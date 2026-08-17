import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String activityName;
  final Color colorStart;
  final Color colorEnd;
  final int? organizationId;

  const WriteReviewScreen({
    super.key,
    required this.activityName,
    required this.colorStart,
    required this.colorEnd,
    this.organizationId,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _selectedStars = 0;
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _photoUrls = [];
  bool _submitted = false;
  bool _saving = false;
  bool _photoUploading = false;

  static const _maxPhotos = 5;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photoUrls.length >= _maxPhotos || _photoUploading) return;
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null || !mounted) return;
    setState(() => _photoUploading = true);
    try {
      final url = await ApiService.uploadFile(xfile.path);
      if (mounted) setState(() => _photoUrls.add(url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          AppLocalizations.of(context)!.failedUploadPhoto,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
      ));
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  void _removePhoto(int index) => setState(() => _photoUrls.removeAt(index));

  Future<void> _submit() async {
    if (_selectedStars == 0) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            l10n.errorRatingRequired,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      );
      return;
    }
    if (widget.organizationId == null) {
      setState(() => _submitted = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.createReview(
        organizationId: widget.organizationId!,
        rating: _selectedStars,
        comment: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : null,
        photoUrls: _photoUrls.isNotEmpty ? List.unmodifiable(_photoUrls) : null,
      );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      final isAlreadyReviewed = e.toString().contains('already_reviewed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isAlreadyReviewed
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            isAlreadyReviewed
                ? AppLocalizations.of(context)!.alreadyReviewed
                : AppLocalizations.of(context)!.failedSubmitReview,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityCard(),
                const SizedBox(height: 28),
                _buildStarRating(),
                const SizedBox(height: 28),
                _buildTextField(),
                const SizedBox(height: 20),
                _buildPhotosSection(),
                const SizedBox(height: 36),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
          Text(
            AppLocalizations.of(context)!.writeReview,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.colorStart, widget.colorEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.sports_soccer_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.activityName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocalizations.of(context)!.reviewingExperience,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    final l10n = AppLocalizations.of(context)!;
    final labels = ['', l10n.ratingPoor, l10n.ratingFair, l10n.ratingGood, l10n.ratingGreat, l10n.ratingExcellent];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourRatingLabel,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _selectedStars = star),
              child: AnimatedScale(
                scale: _selectedStars >= star ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    _selectedStars >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 44,
                    color: _selectedStars >= star
                        ? const Color(0xFFFFD700)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }),
        ),
        if (_selectedStars > 0) ...[
          const SizedBox(height: 10),
          Center(
            child: ShaderMask(
              shaderCallback: (b) =>
                  AppColors.brandGradient.createShader(b),
              child: Text(
                labels[_selectedStars],
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.yourReviewLabel,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _textController,
            maxLines: 5,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.55,
            ),
            cursorColor: AppColors.purple,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.reviewHint,
              hintStyle: GoogleFonts.poppins(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.55,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    final canAdd = _photoUrls.length < _maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.photosLabel,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.photoOptionalCount(_photoUrls.length, _maxPhotos),
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._photoUrls.asMap().entries.map((e) => _buildPhotoTile(e.key, e.value)),
            if (canAdd) _buildAddPhotoTile(),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoTile(int index, String url) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 80,
            height: 80,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceElevated,
                child: const Icon(Icons.image_outlined,
                    color: AppColors.textMuted, size: 28),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile() {
    return GestureDetector(
      onTap: _photoUploading ? null : _pickPhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: _photoUploading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.purple),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 24,
                    color: AppColors.purple.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.addBtn,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _saving ? null : _submit,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  AppLocalizations.of(context)!.submitReviewBtn,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 28),
            Text(
              AppLocalizations.of(context)!.reviewSubmittedTitle,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.reviewSubmittedBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.backToReviewsBtn,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
