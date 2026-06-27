import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/org_models.dart';
import '../services/api_service.dart';
import '../models/app_category.dart';
import 'org_class_form_screen.dart';
import 'org_event_form_screen.dart';
import 'edit_organization_screen.dart';
import 'notifications_settings_screen.dart';
import 'change_password_screen.dart';
import '../routing/transitions.dart';

// ─── Main screen ──────────────────────────────────────────────────────────────

class OrgDashboardScreen extends StatefulWidget {
  final String orgName;
  final String? orgId;

  const OrgDashboardScreen({super.key, this.orgName = '', this.orgId});

  @override
  State<OrgDashboardScreen> createState() => _OrgDashboardState();
}

class _OrgDashboardState extends State<OrgDashboardScreen> {
  int _tab = 0;
  bool _loading = true;
  String _orgId = '';
  String _orgName = '';
  List<OrgClass> _classes = [];
  List<OrgEvent> _events = [];

  String get _initials {
    final name = _orgName.isNotEmpty ? _orgName : 'MO';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _orgName = widget.orgName;
    _orgId = widget.orgId ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (_orgId.isEmpty) {
        final orgs = await ApiService.getMyOrganizations();
        if (orgs.isEmpty) {
          if (mounted) setState(() => _loading = false);
          return;
        }
        final org = orgs.first;
        _orgId = (org['id'] ?? '').toString();
        if (mounted) setState(() => _orgName = (org['name'] ?? _orgName).toString());
      }

      final results = await Future.wait([
        ApiService.getOrgClasses(_orgId),
        ApiService.getOrgEvents(_orgId),
        ApiService.getCategories(),
        ApiService.getAllGroups(),
      ]);

      final rawClasses = results[0] as List<Map<String, dynamic>>;
      final rawEvents = results[1] as List<Map<String, dynamic>>;
      final cats = results[2] as List<AppCategory>;
      final rawGroups = results[3] as List<Map<String, dynamic>>;

      final catMap = {for (final c in cats) c.id: c.name};

      final groupsMap = <String, List<OrgGroup>>{};
      for (final g in rawGroups) {
        final classId = (g['class_id'] ?? '').toString();
        groupsMap.putIfAbsent(classId, () => []).add(OrgGroup(
          name: (g['name'] ?? '').toString(),
          minAge: (g['age_from'] ?? 0) as int,
          maxAge: (g['age_to'] ?? 99) as int,
          capacity: (g['capacity'] ?? 0) as int,
          price: 0,
        ));
      }

      final classes = rawClasses.map((json) {
        final catId = json['category_id']?.toString();
        final classId = (json['id'] ?? '').toString();
        return OrgClass(
          id: classId,
          name: (json['name'] ?? '').toString(),
          category: catId != null ? (catMap[catId] ?? 'Other') : 'Other',
          description: (json['description'] ?? '').toString(),
          groups: groupsMap[classId] ?? [],
        );
      }).toList();

      final events = rawEvents.map((json) {
        final catId = json['category_id']?.toString();
        final startDt = DateTime.tryParse(
              (json['start_datetime'] ?? '').toString(),
            ) ??
            DateTime.now();
        return OrgEvent(
          id: (json['id'] ?? '').toString(),
          name: (json['title'] ?? '').toString(),
          category: catId != null ? (catMap[catId] ?? 'Other') : 'Other',
          description: (json['description'] ?? '').toString(),
          date: startDt,
          time: TimeOfDay(hour: startDt.hour, minute: startDt.minute),
          location: (json['address'] ?? '').toString(),
          minAge: (json['min_age'] ?? 0) as int,
          maxAge: (json['max_age'] ?? 99) as int,
          capacity: (json['capacity'] ?? 0) as int,
          price: (json['price'] as num?)?.toDouble() ?? 0,
          priceComment: json['price_comment']?.toString(),
          isNationwide: json['is_nationwide'] as bool? ?? false,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _classes = classes;
          _events = events;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goAddClass() async {
    await Navigator.of(context).push(
      slideRoute(builder: (_) => OrgClassFormScreen(orgId: _orgId)),
    );
    if (mounted) _loadData();
  }

  Future<void> _goEditClass(OrgClass cls) async {
    final result = await Navigator.of(context).push<OrgClass>(
      slideRoute(builder: (_) => OrgClassFormScreen(orgClass: cls)),
    );
    if (result != null && mounted) {
      setState(() {
        final i = _classes.indexWhere((c) => c.id == result.id);
        if (i >= 0) _classes[i] = result;
      });
    }
  }

  Future<void> _goAddEvent() async {
    await Navigator.of(context).push(
      slideRoute(builder: (_) => OrgEventFormScreen(orgId: _orgId)),
    );
    if (mounted) _loadData();
  }

  Future<void> _goEditEvent(OrgEvent event) async {
    final result = await Navigator.of(context).push<OrgEvent>(
      slideRoute(builder: (_) => OrgEventFormScreen(event: event)),
    );
    if (result != null && mounted) {
      setState(() {
        final i = _events.indexWhere((e) => e.id == result.id);
        if (i >= 0) _events[i] = result;
      });
    }
  }

  Future<void> _deleteClass(OrgClass cls) async {
    final id = int.tryParse(cls.id);
    if (id == null) return;
    try {
      await ApiService.deleteClass(id);
      if (mounted) setState(() => _classes.removeWhere((c) => c.id == cls.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete class. Please try again.',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _deleteEvent(OrgEvent ev) async {
    final id = int.tryParse(ev.id);
    if (id == null) return;
    try {
      await ApiService.deleteEvent(id);
      if (mounted) setState(() => _events.removeWhere((e) => e.id == ev.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete event. Please try again.',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(
            orgName: _orgName,
            initials: _initials,
            classes: _classes,
            events: _events,
            onAddClass: _goAddClass,
            onAddEvent: _goAddEvent,
            onSwitchClasses: () => setState(() => _tab = 1),
            onSwitchEvents: () => setState(() => _tab = 2),
            onEditClass: _goEditClass,
            onEditEvent: _goEditEvent,
          ),
          _ClassesTab(
            classes: _classes,
            onAdd: _goAddClass,
            onEdit: _goEditClass,
            onDelete: _deleteClass,
          ),
          _EventsTab(
            events: _events,
            onAdd: _goAddEvent,
            onEdit: _goEditEvent,
            onDelete: _deleteEvent,
          ),
          const _MessagesTab(),
          _ProfileTab(orgName: _orgName, initials: _initials, orgId: _orgId, onEditComplete: _loadData),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.school_rounded, 'Classes'),
      _NavItem(Icons.event_rounded, 'Events'),
      _NavItem(Icons.chat_bubble_outline_rounded, 'Messages'),
      _NavItem(Icons.business_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = _tab == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tab = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => isSelected
                            ? AppColors.brandGradient.createShader(b)
                            : const LinearGradient(
                                    colors: [
                                      AppColors.textMuted,
                                      AppColors.textMuted
                                    ])
                                .createShader(b),
                        child: Icon(item.icon,
                            size: 22, color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.purple
                              : AppColors.textMuted,
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ─── Dashboard tab ────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final String orgName;
  final String initials;
  final List<OrgClass> classes;
  final List<OrgEvent> events;
  final VoidCallback onAddClass;
  final VoidCallback onAddEvent;
  final VoidCallback onSwitchClasses;
  final VoidCallback onSwitchEvents;
  final void Function(OrgClass)? onEditClass;
  final void Function(OrgEvent)? onEditEvent;

  const _DashboardTab({
    required this.orgName,
    required this.initials,
    required this.classes,
    required this.events,
    required this.onAddClass,
    required this.onAddEvent,
    required this.onSwitchClasses,
    required this.onSwitchEvents,
    this.onEditClass,
    this.onEditEvent,
  });

  int get _totalGroups =>
      classes.fold(0, (s, c) => s + c.groups.length);
  int get _totalStudents =>
      classes.fold(0, (s, c) => s + c.groups.fold(0, (gs, g) => gs + g.capacity));

  @override
  Widget build(BuildContext context) {
    final preview2Classes = classes.take(2).toList();
    final preview2Events = events.take(2).toList();

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'My Classes',
                    actionLabel: '+ Add',
                    onAction: onAddClass,
                    onSeeAll: classes.length > 2 ? onSwitchClasses : null,
                  ),
                  const SizedBox(height: 12),
                  if (preview2Classes.isEmpty)
                    _EmptyHint('No classes yet. Tap + Add to create one.')
                  else
                    ...preview2Classes.map((c) => _ClassPreviewCard(
                          cls: c,
                          onManage: onEditClass != null
                              ? () => onEditClass!(c)
                              : null,
                        )),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'My Events',
                    actionLabel: '+ Add',
                    onAction: onAddEvent,
                    onSeeAll: events.length > 2 ? onSwitchEvents : null,
                  ),
                  const SizedBox(height: 12),
                  if (preview2Events.isEmpty)
                    _EmptyHint('No events yet. Tap + Add to create one.')
                  else
                    ...preview2Events.map((e) => _EventPreviewCard(
                          event: e,
                          onManage: onEditEvent != null
                              ? () => onEditEvent!(e)
                              : null,
                        )),
                  const SizedBox(height: 28),
                  _sectionTitle('Recent Messages'),
                  const SizedBox(height: 12),
                  _buildRecentMessages(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orgName.isNotEmpty ? orgName : 'My Organization',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Organization Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.purple, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.settings_rounded,
                color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = [
      _StatData(
          icon: Icons.school_rounded,
          value: '${classes.length}',
          label: 'Classes',
          color: AppColors.purple),
      _StatData(
          icon: Icons.group_rounded,
          value: '$_totalGroups',
          label: 'Groups',
          color: const Color(0xFF059669)),
      _StatData(
          icon: Icons.people_rounded,
          value: '$_totalStudents',
          label: 'Students',
          color: const Color(0xFF0EA5E9)),
      _StatData(
          icon: Icons.event_rounded,
          value: '${events.length}',
          label: 'Events',
          color: const Color(0xFFEC4899)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats.map((s) => _StatCard(data: s)).toList(),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildRecentMessages() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          'No messages yet.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatData(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  data.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        if (onSeeAll != null) const SizedBox(width: 10),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
      ),
    );
  }
}

class _ClassPreviewCard extends StatelessWidget {
  final OrgClass cls;
  final VoidCallback? onManage;
  const _ClassPreviewCard({required this.cls, this.onManage});

  @override
  Widget build(BuildContext context) {
    final cs = catColorStart(cls.category);
    final ce = catColorEnd(cls.category);
    return GestureDetector(
      onTap: onManage,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [cs, ce],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon(cls.category),
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${cls.category} · ${cls.groups.length} group${cls.groups.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Manage',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventPreviewCard extends StatelessWidget {
  final OrgEvent event;
  final VoidCallback? onManage;
  const _EventPreviewCard({required this.event, this.onManage});

  @override
  Widget build(BuildContext context) {
    final cs = catColorStart(event.category);
    final ce = catColorEnd(event.category);
    return GestureDetector(
      onTap: onManage,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [cs, ce],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon(event.category),
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${fmtDate(event.date)} · ${event.price == 0 ? 'Free' : '₪${event.price.toStringAsFixed(0)}'}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Manage',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Classes tab ──────────────────────────────────────────────────────────────

class _ClassesTab extends StatelessWidget {
  final List<OrgClass> classes;
  final VoidCallback onAdd;
  final void Function(OrgClass) onEdit;
  final void Function(OrgClass) onDelete;

  const _ClassesTab({
    required this.classes,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _TabHeader(title: 'Classes', onAdd: onAdd),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: classes.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: classes.length,
                    itemBuilder: (_, i) => _ClassExpandableCard(
                      cls: classes[i],
                      onEdit: () => onEdit(classes[i]),
                      onDelete: () => onDelete(classes[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.school_outlined,
                size: 38, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text(
            'No Classes Yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No classes yet. Add your first class!',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ClassExpandableCard extends StatefulWidget {
  final OrgClass cls;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassExpandableCard({
    required this.cls,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ClassExpandableCard> createState() =>
      _ClassExpandableCardState();
}

class _ClassExpandableCardState extends State<_ClassExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cls = widget.cls;
    final cs = catColorStart(cls.category);
    final ce = catColorEnd(cls.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [cs, ce],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(catIcon(cls.category),
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cls.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: cs,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${cls.groups.length} group${cls.groups.length != 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _ActionMenu(
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && cls.groups.isNotEmpty) ...[
            const Divider(
                height: 1, color: AppColors.divider, indent: 14),
            ...cls.groups.map(
              (g) => Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: AppColors.divider, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Ages ${g.minAge}–${g.maxAge} · ₪${g.price.toStringAsFixed(0)}/mo · ${g.capacity} students',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textMuted),
                          ),
                          if (g.schedule.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: g.schedule.map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.purple
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${s.day} ${fmtTime(s.start)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.purpleLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
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
          if (_expanded && cls.groups.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Text(
                'No groups added yet.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Events tab ───────────────────────────────────────────────────────────────

class _EventsTab extends StatelessWidget {
  final List<OrgEvent> events;
  final VoidCallback onAdd;
  final void Function(OrgEvent) onEdit;
  final void Function(OrgEvent) onDelete;

  const _EventsTab({
    required this.events,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _TabHeader(title: 'Events', onAdd: onAdd),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: events.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: events.length,
                    itemBuilder: (_, i) => _EventCard(
                      event: events[i],
                      onEdit: () => onEdit(events[i]),
                      onDelete: () => onDelete(events[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.event_outlined,
                size: 38, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text(
            'No Events Yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No events yet. Add your first event!',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final OrgEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = catColorStart(event.category);
    final ce = catColorEnd(event.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Colored header strip
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs, ce]),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _ActionMenu(
                        onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                    Icons.calendar_today_rounded, fmtDate(event.date)),
                const SizedBox(height: 4),
                _InfoRow(Icons.access_time_rounded,
                    fmtTime(event.time)),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _InfoRow(Icons.location_on_rounded,
                      event.location),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Chip(
                      event.category,
                      bgColor: cs.withValues(alpha: 0.12),
                      textColor: cs,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      event.price == 0
                          ? 'Free'
                          : '₪${event.price.toStringAsFixed(0)}',
                      bgColor: AppColors.purple.withValues(alpha: 0.1),
                      textColor: AppColors.purpleLight,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      '${event.capacity} spots',
                      bgColor: const Color(0xFF059669)
                          .withValues(alpha: 0.1),
                      textColor: const Color(0xFF059669),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _Chip(this.label,
      {required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Messages tab ─────────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 36, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Messages Yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Messages from your clients will appear here',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  final String orgName;
  final String initials;
  final String orgId;
  final VoidCallback? onEditComplete;

  const _ProfileTab({
    required this.orgName,
    required this.initials,
    required this.orgId,
    this.onEditComplete,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  Future<void> _navigateEditProfile() async {
    final orgIdInt = int.tryParse(widget.orgId);
    if (orgIdInt == null) {
      _showComingSoon('Edit Profile');
      return;
    }
    final result = await Navigator.of(context).push<dynamic>(
      slideRoute(builder: (_) => EditOrganizationScreen(
        orgId: orgIdInt,
        initialName: widget.orgName,
      )),
    );
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.of(context).pop('deleted');
      return;
    }
    widget.onEditComplete?.call();
  }

  void _navigateChangePassword() {
    Navigator.of(context).push(
      slideRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  void _navigateNotifications() {
    Navigator.of(context).push(
      slideRoute(builder: (_) => const NotificationsSettingsScreen()),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          feature,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This feature is coming soon.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.initials,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.orgName.isNotEmpty ? widget.orgName : 'My Organization',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Verified Organization',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _SettingCard(title: 'Account Settings', items: [
                    _SettingItem(Icons.edit_rounded, 'Edit Profile',
                        onTap: _navigateEditProfile),
                    _SettingItem(Icons.lock_outline_rounded, 'Change Password',
                        onTap: _navigateChangePassword),
                  ]),
                  const SizedBox(height: 16),
                  _SettingCard(title: 'Business', items: [
                    _SettingItem(Icons.notifications_outlined, 'Notifications',
                        onTap: _navigateNotifications),
                    _SettingItem(Icons.payments_outlined, 'Billing & Payments',
                        onTap: () => _showComingSoon('Billing & Payments')),
                    _SettingItem(Icons.bar_chart_rounded, 'Analytics',
                        onTap: () => _showComingSoon('Analytics')),
                  ]),
                  const SizedBox(height: 16),
                  _SettingCard(title: 'Support', items: [
                    _SettingItem(Icons.help_outline_rounded, 'Help Center',
                        onTap: () => _showComingSoon('Help Center')),
                    _SettingItem(Icons.policy_outlined, 'Terms & Privacy',
                        onTap: () => _showComingSoon('Terms & Privacy')),
                  ]),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              size: 18, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Text(
                            'Exit Dashboard',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final List<_SettingItem> items;
  const _SettingCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: items[i].onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.purple
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(items[i].icon,
                                color: AppColors.purple, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              items[i].label,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        color: AppColors.divider,
                        indent: 60),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SettingItem(this.icon, this.label, {this.onTap});
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _TabHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _TabHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'New $title'.replaceAll('New Classes', 'New Class').replaceAll('New Events', 'New Event'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.textMuted, size: 18),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text('Edit',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Text('Delete',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
  }
}
