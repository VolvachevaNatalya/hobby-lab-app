import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/org_photo.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

// ─── Social URL helpers ───────────────────────────────────────────────────────

/// Strip a known URL prefix, handling https/http/www variants.
String _stripSocial(String? raw, String prefix) {
  if (raw == null || raw.isEmpty) return '';
  final variants = [
    prefix,
    'https://$prefix',
    'http://$prefix',
    'https://www.$prefix',
    'http://www.$prefix',
    'www.$prefix',
  ];
  final lower = raw.toLowerCase();
  for (final v in variants) {
    if (lower.startsWith(v.toLowerCase())) return raw.substring(v.length);
  }
  return raw;
}

/// Build a full URL by prepending prefix to the typed username.
String? _withSocialPrefix(String username, String prefix) {
  final u = username.trim();
  return u.isEmpty ? null : '$prefix$u';
}

// ─────────────────────────────────────────────────────────────────────────────

class EditOrganizationScreen extends StatefulWidget {
  final int orgId;
  final String initialName;
  final String initialDescription;
  final String initialPhone;
  final String initialEmail;
  final String initialWebsite;
  final String initialAddress;
  final String initialCity;

  const EditOrganizationScreen({
    super.key,
    required this.orgId,
    this.initialName = '',
    this.initialDescription = '',
    this.initialPhone = '',
    this.initialEmail = '',
    this.initialWebsite = '',
    this.initialAddress = '',
    this.initialCity = '',
  });

  @override
  State<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _facebookCtrl;
  late final TextEditingController _telegramCtrl;
  late final TextEditingController _youtubeCtrl;
  late final TextEditingController _tiktokCtrl;
  late final TextEditingController _whatsappCtrl;
  late final TextEditingController _trialPriceCtrl;
  late final TextEditingController _trialCommentCtrl;
  bool _trialAvailable = false;

  String? _logoPath;
  String? _bannerPath;
  String? _logoUrl;
  String? _bannerUrl;

  List<OrgPhoto> _photos = [];
  bool _photosLoading = false;

  final _nameKey = GlobalKey();

  bool _saving = false;
  bool _loading = true;
  bool _submitted = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDescription);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _websiteCtrl = TextEditingController(text: widget.initialWebsite);
    _addressCtrl = TextEditingController(text: widget.initialAddress);
    _cityCtrl = TextEditingController(text: widget.initialCity);
    _instagramCtrl = TextEditingController();
    _facebookCtrl = TextEditingController();
    _telegramCtrl = TextEditingController();
    _youtubeCtrl = TextEditingController();
    _tiktokCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
    _trialPriceCtrl = TextEditingController();
    _trialCommentCtrl = TextEditingController();
    _nameCtrl.addListener(_onFieldChanged);
    _loadOrgData();
  }

  void _onFieldChanged() {
    if (_submitted && mounted) setState(() {});
  }

  Future<void> _loadOrgData() async {
    try {
      final org = await ApiService.getOrganization(widget.orgId.toString());
      if (!mounted) return;
      _nameCtrl.text = org['name'] ?? '';
      _descCtrl.text = org['description'] ?? '';
      _phoneCtrl.text = org['phone'] ?? '';
      _emailCtrl.text = org['email'] ?? '';
      _websiteCtrl.text = org['website'] ?? '';
      _addressCtrl.text = org['address'] ?? '';
      _cityCtrl.text = org['city'] ?? '';
      _instagramCtrl.text = _stripSocial(org['instagram_url'] as String?, 'instagram.com/');
      _facebookCtrl.text  = _stripSocial(org['facebook_url']  as String?, 'facebook.com/');
      _telegramCtrl.text  = _stripSocial(org['telegram_url']  as String?, 't.me/');
      _youtubeCtrl.text   = _stripSocial(org['youtube_url']   as String?, 'youtube.com/');
      _tiktokCtrl.text    = _stripSocial(org['tiktok_url']    as String?, 'tiktok.com/@');
      _whatsappCtrl.text  = org['whatsapp_url'] as String? ?? '';
      _logoUrl = org['logo_url'] as String?;
      _bannerUrl = org['banner_url'] as String?;
      _trialAvailable = org['trial_lesson_available'] as bool? ?? false;
      final rawPrice = org['trial_lesson_price'];
      _trialPriceCtrl.text = rawPrice != null ? '$rawPrice' : '';
      _trialCommentCtrl.text = org['trial_lesson_comment'] as String? ?? '';
    } catch (_) {
      // keep constructor-provided initial values if load fails
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final photos =
          await ApiService.getOrgPhotos(widget.orgId.toString());
      if (mounted) setState(() => _photos = photos);
    } catch (_) {}
  }

  Future<void> _pickAndUploadPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    if (_photos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.photoLimitReached,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final xfile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null || !mounted) return;
    setState(() => _photosLoading = true);
    try {
      final photo = await ApiService.addOrgPhoto(
          widget.orgId.toString(), xfile.path);
      if (mounted) setState(() => _photos = [..._photos, photo]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload photo',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _photosLoading = false);
    }
  }

  Future<void> _deletePhoto(OrgPhoto photo) async {
    setState(() =>
        _photos = _photos.where((p) => p.id != photo.id).toList());
    try {
      await ApiService.deleteOrgPhoto(
          widget.orgId.toString(), photo.id);
    } catch (_) {
      if (mounted) setState(() => _photos = [..._photos, photo]);
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _telegramCtrl.dispose();
    _youtubeCtrl.dispose();
    _tiktokCtrl.dispose();
    _whatsappCtrl.dispose();
    _trialPriceCtrl.dispose();
    _trialCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null || !mounted) return;
    setState(() {
      if (isLogo) {
        _logoPath = xfile.path;
      } else {
        _bannerPath = xfile.path;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return; // prevent double-tap

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _submitted = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_nameKey.currentContext != null) {
          Scrollable.ensureVisible(
            _nameKey.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateOrganization(
        widget.orgId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        website: _websiteCtrl.text.trim().isNotEmpty ? _websiteCtrl.text.trim() : null,
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        instagramUrl: _withSocialPrefix(_instagramCtrl.text, 'instagram.com/'),
        facebookUrl:  _withSocialPrefix(_facebookCtrl.text,  'facebook.com/'),
        telegramUrl:  _withSocialPrefix(_telegramCtrl.text,  't.me/'),
        youtubeUrl:   _withSocialPrefix(_youtubeCtrl.text,   'youtube.com/'),
        tiktokUrl:    _withSocialPrefix(_tiktokCtrl.text,    'tiktok.com/@'),
        whatsappUrl:  _whatsappCtrl.text.trim().isNotEmpty ? _whatsappCtrl.text.trim() : null,
        logoUrl: _logoPath ?? (_logoUrl?.isNotEmpty == true ? _logoUrl : null),
        bannerUrl: _bannerPath ?? (_bannerUrl?.isNotEmpty == true ? _bannerUrl : null),
        trialLessonAvailable: _trialAvailable,
        trialLessonPrice: _trialAvailable && _trialPriceCtrl.text.trim().isNotEmpty
            ? double.tryParse(_trialPriceCtrl.text.trim())
            : null,
        trialLessonComment: _trialAvailable && _trialCommentCtrl.text.trim().isNotEmpty
            ? _trialCommentCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      _showSnack('Changes saved successfully', const Color(0xFF059669));
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (mounted) _showSnack('Failed to save changes', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.purple),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field('Organization Name', _nameCtrl, key: _nameKey, required: true, hasError: _submitted && _nameCtrl.text.trim().isEmpty),
                      const SizedBox(height: 16),
                      _field('Description', _descCtrl, maxLines: 3),
                      const SizedBox(height: 16),
                      _field('Phone', _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined),
                      const SizedBox(height: 16),
                      _field('Email', _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined),
                      const SizedBox(height: 16),
                      _field('Website', _websiteCtrl,
                          keyboardType: TextInputType.url,
                          prefixIcon: Icons.language_rounded),
                      const SizedBox(height: 16),
                      _field('Address', _addressCtrl,
                          prefixIcon: Icons.location_on_outlined),
                      const SizedBox(height: 16),
                      _field('City', _cityCtrl,
                          prefixIcon: Icons.location_city_rounded),
                      const SizedBox(height: 24),
                      _sectionLabel('Social Media'),
                      const SizedBox(height: 12),
                      _field('Instagram', _instagramCtrl,
                          prefixIcon: Icons.camera_alt_rounded,
                          prefixIconColor: const Color(0xFFE1306C),
                          urlPrefix: 'instagram.com/'),
                      const SizedBox(height: 16),
                      _field('Facebook', _facebookCtrl,
                          prefixIcon: Icons.thumb_up_alt_rounded,
                          prefixIconColor: const Color(0xFF1877F2),
                          urlPrefix: 'facebook.com/'),
                      const SizedBox(height: 16),
                      _field(l10n.fieldTelegram, _telegramCtrl,
                          prefixIcon: Icons.send_rounded,
                          prefixIconColor: const Color(0xFF229ED9),
                          urlPrefix: 't.me/'),
                      const SizedBox(height: 16),
                      _field(l10n.fieldYouTube, _youtubeCtrl,
                          prefixIcon: Icons.smart_display_rounded,
                          prefixIconColor: const Color(0xFFFF0000),
                          urlPrefix: 'youtube.com/'),
                      const SizedBox(height: 16),
                      _field(l10n.fieldTikTok, _tiktokCtrl,
                          prefixWidget: const FaIcon(
                            FontAwesomeIcons.tiktok,
                            size: 18,
                            color: Color(0xFF010101),
                          ),
                          urlPrefix: 'tiktok.com/@'),
                      const SizedBox(height: 16),
                      _field(l10n.fieldWhatsApp, _whatsappCtrl,
                          keyboardType: TextInputType.phone,
                          prefixWidget: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            size: 18,
                            color: Color(0xFF25D366),
                          ),
                          fieldHint: '+972...'),
                      const SizedBox(height: 24),
                      _sectionLabel(l10n.trialLesson),
                      const SizedBox(height: 12),
                      _buildTrialToggle(l10n),
                      if (_trialAvailable) ...[
                        const SizedBox(height: 16),
                        _field(l10n.trialLessonPrice, _trialPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.attach_money_rounded,
                            fieldHint: '0.00'),
                        const SizedBox(height: 16),
                        _field(l10n.trialLessonComment, _trialCommentCtrl, maxLines: 3),
                      ],
                      const SizedBox(height: 24),
                      _sectionLabel('Media'),
                      const SizedBox(height: 12),
                      _imagePicker(
                        label: 'Logo',
                        imagePath: _logoPath,
                        existingUrl: _logoUrl,
                        onPick: () => _pickImage(true),
                      ),
                      const SizedBox(height: 16),
                      _imagePicker(
                        label: 'Banner',
                        imagePath: _bannerPath,
                        existingUrl: _bannerUrl,
                        onPick: () => _pickImage(false),
                      ),
                      const SizedBox(height: 24),
                      _buildPhotosSection(context),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
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
            'Edit Profile',
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

  Widget _buildTrialToggle(dynamic l10n) {
    return GestureDetector(
      onTap: () => setState(() => _trialAvailable = !_trialAvailable),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _trialAvailable
              ? AppColors.purple.withValues(alpha: 0.07)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _trialAvailable ? AppColors.purple.withValues(alpha: 0.3) : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.school_rounded, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${l10n.trialLesson} available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Switch(
              value: _trialAvailable,
              onChanged: (v) => setState(() => _trialAvailable = v),
              activeColor: AppColors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _imagePicker({
    required String label,
    required String? imagePath,
    required String? existingUrl,
    required VoidCallback onPick,
  }) {
    final hasLocal = imagePath != null;
    final hasRemote = existingUrl != null && existingUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: hasLocal
                        ? Image.file(File(imagePath), fit: BoxFit.cover)
                        : hasRemote
                            ? Image.network(
                                existingUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderIcon(),
                              )
                            : _placeholderIcon(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocal ? 'Image selected' : 'Choose from gallery',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: hasLocal
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (hasLocal) ...[
                        const SizedBox(height: 2),
                        Text(
                          imagePath.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ] else if (hasRemote) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Tap to replace',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 28),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    Key? key,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    IconData? prefixIcon,
    Widget? prefixWidget,   // for non-Material icons (e.g. FontAwesome)
    Color? prefixIconColor,
    bool hasError = false,
    String? urlPrefix,      // inline text prefix e.g. "instagram.com/"
    String? fieldHint,      // custom hint text (e.g. WhatsApp placeholder)
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasIconPrefix = prefixIcon != null || prefixWidget != null;
    Widget? builtIcon;
    if (prefixWidget != null) {
      builtIcon = Padding(
        padding: const EdgeInsets.only(left: 12),
        child: prefixWidget,
      );
    } else if (prefixIcon != null) {
      builtIcon = Icon(prefixIcon, size: 20,
          color: prefixIconColor ?? AppColors.textMuted);
    }
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (required)
              Text(' *',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? const Color(0xFFEF4444) : AppColors.divider,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            autocorrect: false,
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontSize: 14),
            cursorColor: AppColors.purple,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: fieldHint,
              hintStyle: GoogleFonts.poppins(
                  color: AppColors.textMuted, fontSize: 14),
              // Inline URL prefix shown before typed text
              prefix: urlPrefix != null
                  ? Text(urlPrefix,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppColors.textSecondary))
                  : null,
              contentPadding: EdgeInsets.only(
                left: urlPrefix != null ? 0 : (hasIconPrefix ? 4 : 14),
                right: 14,
                top: 12,
                bottom: 12,
              ),
              prefixIcon: builtIcon,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(l10n.fieldRequired,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: const Color(0xFFEF4444))),
          ),
      ],
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canAdd = _photos.length < 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(l10n.photosSection),
            const SizedBox(width: 8),
            Text(
              '(${_photos.length}/10)',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            if (_photosLoading) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.purple),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._photos.map((photo) => _PhotoTile(
                  photo: photo,
                  onDelete: () => _deletePhoto(photo),
                )),
            if (canAdd)
              GestureDetector(
                onTap: _photosLoading ? null : _pickAndUploadPhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 24,
                          color: AppColors.purple.withValues(alpha: 0.8)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.addPhoto,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        width: double.infinity,
        height: 54,
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
                  'Save Changes',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Photo tile ───────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final OrgPhoto photo;
  final VoidCallback onDelete;
  const _PhotoTile({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLocal = photo.photoUrl.startsWith('/') ||
        photo.photoUrl.startsWith('file://');
    final localPath = photo.photoUrl.startsWith('file://')
        ? photo.photoUrl.substring(7)
        : photo.photoUrl;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 80,
            height: 80,
            child: isLocal
                ? Image.file(File(localPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : Image.network(photo.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder()),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceElevated,
        child: const Icon(Icons.image_outlined,
            color: AppColors.textMuted, size: 28),
      );
}
