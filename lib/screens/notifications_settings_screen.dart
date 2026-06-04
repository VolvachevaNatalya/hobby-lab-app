import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

const _toggleItems = [
  _ToggleData(
    icon: Icons.calendar_today_rounded,
    iconColor: Color(0xFF0EA5E9),
    title: 'Appointment Notifications',
    subtitle: 'Reminders about upcoming classes and bookings',
  ),
  _ToggleData(
    icon: Icons.chat_bubble_rounded,
    iconColor: Color(0xFF7C3AED),
    title: 'Chat Notifications',
    subtitle: 'New messages from organizers',
  ),
  _ToggleData(
    icon: Icons.explore_rounded,
    iconColor: Color(0xFF059669),
    title: 'Activity Updates',
    subtitle: 'Changes to activities you\'ve booked or saved',
  ),
  _ToggleData(
    icon: Icons.local_offer_rounded,
    iconColor: Color(0xFFF59E0B),
    title: 'Offers & Promotions',
    subtitle: 'Flash deals, discounts, and special events',
  ),
];

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  final _keys = [
    'notif_appointments',
    'notif_chat',
    'notif_activity',
    'notif_offers',
  ];
  var _values = [true, true, false, true];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _values = List.generate(
        _keys.length,
        (i) => prefs.getBool(_keys[i]) ?? _values[i],
      );
    });
  }

  Future<void> _toggle(int i, bool v) async {
    setState(() => _values[i] = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keys[i], v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose which notifications you want to receive',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: List.generate(_toggleItems.length, (i) {
                          return Column(
                            children: [
                              _ToggleRow(
                                data: _toggleItems[i],
                                value: _values[i],
                                onChanged: (v) => _toggle(i, v),
                              ),
                              if (i < _toggleItems.length - 1)
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

  Widget _buildHeader(BuildContext context) {
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
            'Notifications',
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
