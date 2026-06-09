import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hobby_lab/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'saved_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final tabNotifier = ValueNotifier<int>(0);

  static void switchTab(int index) => tabNotifier.value = index;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _unreadMessages = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    MessagesScreen(),
    SavedScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainShell.tabNotifier.addListener(_onTabChange);
    _refreshUnread();
  }

  @override
  void dispose() {
    MainShell.tabNotifier.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (!mounted) return;
    final newIndex = MainShell.tabNotifier.value;
    if (_currentIndex == newIndex) return;
    setState(() => _currentIndex = newIndex);
    if (newIndex == 1) _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final convos = await ApiService.getConversations();
      if (!mounted) return;
      final total = convos.fold<int>(0, (sum, c) => sum + c.unreadCount);
      setState(() => _unreadMessages = total);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = [
      _NavItem(
          icon: Icons.home_rounded,
          outlinedIcon: Icons.home_outlined,
          label: l10n.navHome),
      _NavItem(
          icon: Icons.chat_bubble_rounded,
          outlinedIcon: Icons.chat_bubble_outline_rounded,
          label: l10n.navMessages),
      _NavItem(
          icon: Icons.bookmark_rounded,
          outlinedIcon: Icons.bookmark_outline_rounded,
          label: l10n.navSaved),
      _NavItem(
          icon: Icons.notifications_rounded,
          outlinedIcon: Icons.notifications_outlined,
          label: l10n.navAlerts),
      _NavItem(
          icon: Icons.person_rounded,
          outlinedIcon: Icons.person_outline_rounded,
          label: l10n.navProfile),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: navItems,
        unreadMessages: _unreadMessages,
        onTap: (i) {
          setState(() => _currentIndex = i);
          MainShell.tabNotifier.value = i;
          if (i == 1) _refreshUnread();
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final int unreadMessages;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.unreadMessages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = currentIndex == i;
              final showBadge = i == 1 && unreadMessages > 0;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          isActive
                              ? ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.brandGradient
                                          .createShader(bounds),
                                  child: Icon(item.icon,
                                      size: 24, color: Colors.white),
                                )
                              : Icon(item.outlinedIcon,
                                  size: 24, color: AppColors.textMuted),
                          if (showBadge)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  unreadMessages > 99
                                      ? '99+'
                                      : '$unreadMessages',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isActive ? AppColors.purple : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
