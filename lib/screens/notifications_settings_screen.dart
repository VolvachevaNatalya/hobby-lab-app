import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class _ToggleData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ToggleData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

// Mapping between toggle index and SharedPreferences / API keys.
const _prefKeys = [
  'notif_appointments',
  'notif_chat',
  'notif_activity',
  'notif_offers',
];

const _defaultValues = [true, true, false, true];

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  var _values = List<bool>.from(_defaultValues);
  bool _loadingInitial = true;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  /// Load order: API → SharedPreferences fallback.
  /// SharedPreferences is used as an offline cache: always written on
  /// successful API load / save.
  Future<void> _loadPrefs() async {
    final cached = await _loadFromSharedPrefs();
    if (mounted) setState(() { _values = cached; _loadingInitial = false; });

    try {
      final apiPrefs = await ApiService.getNotificationPreferences();
      if (!mounted) return;
      final apiValues = [
        apiPrefs['notif_appointments'] ?? true,
        apiPrefs['notif_chat'] ?? true,
        apiPrefs['notif_activity'] ?? false,
        apiPrefs['notif_offers'] ?? true,
      ];
      setState(() => _values = apiValues);
      await _saveToSharedPrefs(apiValues);
    } catch (_) {
      // Network failure: keep the cached values already shown.
    }
  }

  Future<List<bool>> _loadFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return List.generate(
      _prefKeys.length,
      (i) => prefs.getBool(_prefKeys[i]) ?? _defaultValues[i],
    );
  }

  Future<void> _saveToSharedPrefs(List<bool> values) async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < _prefKeys.length; i++) {
      await prefs.setBool(_prefKeys[i], values[i]);
    }
  }

  Future<void> _toggle(int i, bool v) async {
    final previous = List<bool>.from(_values);
    setState(() { _values[i] = v; _saveError = null; });

    // Optimistic: update local cache immediately.
    final updated = List<bool>.from(_values);
    await _saveToSharedPrefs(updated);

    try {
      await ApiService.updateNotificationPreferences({
        for (var j = 0; j < _prefKeys.length; j++) _prefKeys[j]: updated[j],
      });
    } catch (_) {
      // Roll back optimistic update on failure.
      if (mounted) {
        setState(() {
          _values = previous;
          final l10n = AppLocalizations.of(context);
          _saveError = l10n?.notifPrefSaveFailed;
        });
        await _saveToSharedPrefs(previous);
      }
    }
  }

  List<_ToggleData> _buildItems(AppLocalizations l10n) => [
    _ToggleData(
      icon: Icons.calendar_today_rounded,
      iconColor: const Color(0xFF0EA5E9),
      title: l10n.notifAppointmentsTitle,
      subtitle: l10n.notifAppointmentsSubtitle,
    ),
    _ToggleData(
      icon: Icons.chat_bubble_rounded,
      iconColor: const Color(0xFF7C3AED),
      title: l10n.notifChatTitle,
      subtitle: l10n.notifChatSubtitle,
    ),
    _ToggleData(
      icon: Icons.explore_rounded,
      iconColor: const Color(0xFF059669),
      title: l10n.notifActivityTitle,
      subtitle: l10n.notifActivitySubtitle,
    ),
    _ToggleData(
      icon: Icons.local_offer_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: l10n.notifOffersTitle,
      subtitle: l10n.notifOffersSubtitle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toggleItems = _buildItems(l10n);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, l10n),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: _loadingInitial
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.notifChooseDesc,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                          if (_saveError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _saveError!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              children: List.generate(toggleItems.length, (i) {
                                return Column(
                                  children: [
                                    _ToggleRow(
                                      data: toggleItems[i],
                                      value: _values[i],
                                      onChanged: (v) => _toggle(i, v),
                                    ),
                                    if (i < toggleItems.length - 1)
                                      const Divider(
                                        height: 1,
                                        color: AppColors.divider,
                                        indent: 64,
                                        endIndent: 16,
                                      ),
                                  ],
                                );
                              }),
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

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
            l10n.notifications,
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
}

class _ToggleRow extends StatelessWidget {
  final _ToggleData data;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.data,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 20, color: data.iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.purple,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceElevated,
          ),
        ],
      ),
    );
  }
}
