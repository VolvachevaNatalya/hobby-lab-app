import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/app_category.dart';
import '../models/app_city.dart';
import '../models/org_models.dart';
import '../routing/transitions.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'city_picker_screen.dart';
import 'org_dashboard_screen.dart';

// ─── Social URL helpers ───────────────────────────────────────────────────────

String? _withSocialPrefix(String username, String prefix) {
  final u = username.trim();
  return u.isEmpty ? null : '$prefix$u';
}

class _DaySchedule {
  bool enabled;
  TimeOfDay open;
  TimeOfDay close;

  _DaySchedule({
    required this.enabled,
    required this.open,
    required this.close,
  });
}

class OrganizationRegistrationScreen extends StatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  State<OrganizationRegistrationScreen> createState() =>
      _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState
    extends State<OrganizationRegistrationScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _telegramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _whatsappController = TextEditingController();

  final _nameKey = GlobalKey();

  AppCity? _selectedCity;
  final List<AppCategory> _selectedCategories = [];
  List<AppCategory> _categories = [];
  bool _loadingCategories = true;
  bool _saving = false;
  bool _submitted = false;

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  late final Map<String, _DaySchedule> _schedule;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _schedule = {
      for (var i = 0; i < _days.length; i++)
        _days[i]: _DaySchedule(
          enabled: i >= 1 && i <= 5,
          open: const TimeOfDay(hour: 9, minute: 0),
          close: const TimeOfDay(hour: 18, minute: 0),
        ),
    };
    _loadCategories();
  }

  void _onFieldChanged() {
    if (_submitted && mounted) setState(() {});
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) setState(() { _categories = cats; _loadingCategories = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _telegramController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _showCategorySheet() {
    if (_loadingCategories) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void toggle(AppCategory cat) {
            final isSelected = _selectedCategories.any((c) => c.id == cat.id);
            if (isSelected) {
              setState(() => _selectedCategories.removeWhere((c) => c.id == cat.id));
              setModalState(() {});
            } else {
              if (_selectedCategories.length >= 10) {
                messenger.showSnackBar(SnackBar(
                  content: Text(l10n.maxCategoriesReached,
                      style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
                return;
              }
              setState(() => _selectedCategories.add(cat));
              setModalState(() {});
            }
          }

          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.selectCategories,
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedCategories.length}/10',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.purpleLight),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.divider),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = _selectedCategories.any((c) => c.id == cat.id);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => toggle(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.purple.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    gradient: sel
                                        ? LinearGradient(colors: [
                                            catColorStart(cat.name),
                                            catColorEnd(cat.name),
                                          ])
                                        : null,
                                    color: sel ? null : AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(catIcon(cat.name),
                                      size: 16,
                                      color: sel ? Colors.white : AppColors.textMuted),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(cat.name,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: sel
                                              ? AppColors.purpleLight
                                              : AppColors.textPrimary,
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.w400)),
                                ),
                                if (sel)
                                  const Icon(Icons.check_rounded,
                                      color: AppColors.purple, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: GestureDetector(
                      onTap: () => Navigator.of(sheetCtx).pop(),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('Done',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickTime(String day, bool isOpen) async {
    final sched = _schedule[day]!;
    final initial = isOpen ? sched.open : sched.close;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.purple,
            onSurface: AppColors.textPrimary,
            surface: AppColors.surface,
          ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: AppColors.surface,
            hourMinuteColor: AppColors.surfaceElevated,
            dialBackgroundColor: AppColors.surfaceElevated,
            dialHandColor: AppColors.purple,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isOpen) {
          _schedule[day]!.open = picked;
        } else {
          _schedule[day]!.close = picked;
        }
      });
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _submit() async {
    if (_saving) return; // prevent double-tap

    if (_nameController.text.trim().isEmpty || _selectedCategories.isEmpty) {
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
    final catIds = _selectedCategories
        .map((c) => int.tryParse(c.id))
        .whereType<int>()
        .toList();
    try {
      final orgData = await ApiService.createOrganization(
        name: _nameController.text.trim(),
        categoryIds: catIds.isNotEmpty ? catIds : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        cityId: _selectedCity?.id,
        instagramUrl: _withSocialPrefix(_instagramController.text, 'instagram.com/'),
        facebookUrl:  _withSocialPrefix(_facebookController.text,  'facebook.com/'),
        telegramUrl:  _withSocialPrefix(_telegramController.text,  't.me/'),
        youtubeUrl:   _withSocialPrefix(_youtubeController.text,   'youtube.com/'),
        tiktokUrl:    _withSocialPrefix(_tiktokController.text,    'tiktok.com/@'),
        whatsappUrl:  _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : null,
      );
      if (!mounted) return;
      final orgId = (orgData['id'] ?? '').toString();
      final orgName = (orgData['name'] ?? _nameController.text.trim()).toString();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, _, _) =>
              OrgDashboardScreen(orgId: orgId, orgName: orgName),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to register. Please try again.', const Color(0xFFEF4444));
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
        child: _buildForm(),
      ),
      ),
    );
  }

  // ── Form ─────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                _buildLogoUpload(),
                const SizedBox(height: 28),
                _sectionLabel('Organization Details'),
                const SizedBox(height: 12),
                _buildNameCard(),
                const SizedBox(height: 20),
                _sectionLabel('Contact Information'),
                const SizedBox(height: 12),
                _buildCard([
                  _buildInlineField(
                    controller: _phoneController,
                    hint: 'Phone number',
                    icon: Icons.phone_outlined,
                    type: TextInputType.phone,
                  ),
                  _cardDivider(),
                  _buildInlineField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  _cardDivider(),
                  _buildInlineField(
                    controller: _websiteController,
                    hint: 'Website (optional)',
                    icon: Icons.language_rounded,
                    type: TextInputType.url,
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionLabel('Location'),
                const SizedBox(height: 12),
                _buildCard([
                  _buildInlineField(
                    controller: _addressController,
                    hint: 'Address',
                    icon: Icons.location_on_outlined,
                  ),
                  _cardDivider(),
                  _buildCityPickerRow(),
                ]),
                const SizedBox(height: 20),
                _sectionLabel('Social Media'),
                const SizedBox(height: 12),
                _buildCard([
                  _buildInlineField(
                    controller: _instagramController,
                    hint: 'Instagram',
                    icon: Icons.camera_alt_rounded,
                    customIcon: const Icon(Icons.camera_alt_rounded,
                        size: 20, color: Color(0xFFE1306C)),
                    urlPrefix: 'instagram.com/',
                  ),
                  _cardDivider(),
                  _buildInlineField(
                    controller: _facebookController,
                    hint: 'Facebook',
                    icon: Icons.thumb_up_alt_rounded,
                    customIcon: const Icon(Icons.thumb_up_alt_rounded,
                        size: 20, color: Color(0xFF1877F2)),
                    urlPrefix: 'facebook.com/',
                  ),
                  _cardDivider(),
                  _buildInlineField(
                    controller: _telegramController,
                    hint: 'Telegram',
                    icon: Icons.send_rounded,
                    customIcon: const Icon(Icons.send_rounded,
                        size: 20, color: Color(0xFF229ED9)),
                    urlPrefix: 't.me/',
                  ),
                  _cardDivider(),
                  _buildInlineField(
                    controller: _youtubeController,
                    hint: 'YouTube',
                    icon: Icons.smart_display_rounded,
                    customIcon: const Icon(Icons.smart_display_rounded,
                        size: 20, color: Color(0xFFFF0000)),
                    urlPrefix: 'youtube.com/',
                  ),
                  _cardDivider(),
                  _buildInlineField(
                    controller: _tiktokController,
                    hint: 'TikTok',
                    icon: Icons.music_note_rounded,
                    customIcon: const FaIcon(FontAwesomeIcons.tiktok,
                        size: 18, color: Color(0xFF010101)),
                    urlPrefix: 'tiktok.com/@',
                  ),
                  _cardDivider(),
                  _buildInlineField(
                    controller: _whatsappController,
                    hint: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    customIcon: const FaIcon(FontAwesomeIcons.whatsapp,
                        size: 18, color: Color(0xFF25D366)),
                    type: TextInputType.phone,
                    fieldHint: '+972...',
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionLabel('Working Hours'),
                const SizedBox(height: 12),
                _buildWorkingHours(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          const SizedBox(width: 14),
          Text(
            'Become a Provider',
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

  Widget _buildLogoUpload() {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Upload Logo',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
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

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNameCard() {
    final l10n = AppLocalizations.of(context)!;
    final nameError = _submitted && _nameController.text.trim().isEmpty;
    final catError = _submitted && _selectedCategories.isEmpty;
    return Column(
      key: _nameKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (nameError || catError)
                  ? const Color(0xFFEF4444)
                  : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              _buildInlineField(
                controller: _nameController,
                hint: 'Organization name',
                icon: Icons.business_rounded,
                isRequired: true,
                error: nameError,
              ),
              _cardDivider(),
              _buildDescriptionField(),
              _cardDivider(),
              _buildCategoryField(error: catError),
            ],
          ),
        ),
        if (nameError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              l10n.fieldRequired,
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
            ),
          ),
        if (catError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              'Please select at least one category',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
            ),
          ),
      ],
    );
  }

  Widget _cardDivider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
        indent: 52,
      );

  static const _requiredStyle = TextStyle(
    color: Color(0xFFEF4444),
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  Widget _buildInlineField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Widget? customIcon, // for FontAwesome or other non-Material icons
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool isRequired = false,
    bool error = false,
    String? urlPrefix,  // inline text prefix, e.g. "instagram.com/"
    String? fieldHint,  // override hint shown inside field (for WhatsApp)
  }) {
    final Widget displayIcon = customIcon ??
        Icon(icon!, size: 20,
            color: error ? const Color(0xFFEF4444) : AppColors.textMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          displayIcon,
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: type,
              textInputAction: action,
              autocorrect: false,
              style: GoogleFonts.poppins(
                  color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: fieldHint ?? (urlPrefix == null ? hint : null),
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                prefix: urlPrefix != null
                    ? Text(urlPrefix,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary))
                    : null,
                contentPadding: EdgeInsets.only(
                  left: urlPrefix != null ? 0 : 0,
                  top: 16,
                  bottom: 16,
                ),
              ),
            ),
          ),
          if (isRequired)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, val, __) => val.text.trim().isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Text('*', style: _requiredStyle),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Icon(Icons.notes_rounded,
                size: 20, color: AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _descriptionController,
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.poppins(
                  color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryField({bool error = false}) {
    final empty = _selectedCategories.isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showCategorySheet,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.category_rounded,
                  size: 20,
                  color: error ? const Color(0xFFEF4444) : AppColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: empty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Categories',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: error
                              ? const Color(0xFFEF4444)
                              : AppColors.textMuted,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedCategories
                            .map((cat) => _buildCategoryChip(cat))
                            .toList(),
                      ),
                    ),
            ),
            if (empty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: const Text('*', style: _requiredStyle),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(AppCategory cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColorStart(cat.name).withValues(alpha: 0.25),
            catColorEnd(cat.name).withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: catColorStart(cat.name).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(catIcon(cat.name), size: 11, color: catColorStart(cat.name)),
          const SizedBox(width: 4),
          Text(cat.name,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() =>
                _selectedCategories.removeWhere((c) => c.id == cat.id)),
            child: const Icon(Icons.close, size: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _openCityPicker() async {
    final city = await Navigator.of(context).push<AppCity>(
      modalRoute(builder: (_) => const CityPickerScreen()),
    );
    if (city != null && mounted) {
      setState(() => _selectedCity = city);
    }
  }

  Widget _buildCityPickerRow() {
    final lang = Localizations.localeOf(context).languageCode;
    final label = _selectedCity?.displayName(lang);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCityPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.location_city_rounded, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label ?? 'City',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: label != null ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHours() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(_days.length, (i) {
          final day = _days[i];
          final sched = _schedule[day]!;
          return Column(
            children: [
              _DayRow(
                day: day,
                schedule: sched,
                onToggle: (v) => setState(() => sched.enabled = v),
                onPickOpen: () => _pickTime(day, true),
                onPickClose: () => _pickTime(day, false),
              ),
              if (i < _days.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
            ],
          );
        }),
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
              color: AppColors.purple.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                  'Submit Application',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

}

// ── Local helper widgets ───────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final String day;
  final _DaySchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;

  const _DayRow({
    required this.day,
    required this.schedule,
    required this.onToggle,
    required this.onPickOpen,
    required this.onPickClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _GradientSwitch(value: schedule.enabled, onChanged: onToggle),
          const SizedBox(width: 13),
          SizedBox(
            width: 34,
            child: Text(
              day,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: schedule.enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
          const Spacer(),
          if (schedule.enabled) ...[
            _TimeChip(time: schedule.open, onTap: onPickOpen),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '–',
                style: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
              ),
            ),
            _TimeChip(time: schedule.close, onTap: onPickClose),
          ] else
            Text(
              'Closed',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeChip({required this.time, required this.onTap});

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        child: Text(
          _fmt(time),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.purpleLight,
          ),
        ),
      ),
    );
  }
}

class _GradientSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GradientSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: value ? AppColors.brandGradient : null,
          color: value ? null : AppColors.surfaceElevated,
          border: value
              ? null
              : Border.all(color: AppColors.divider),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
