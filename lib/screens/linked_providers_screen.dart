import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LinkedProvidersScreen extends StatefulWidget {
  const LinkedProvidersScreen({super.key});

  @override
  State<LinkedProvidersScreen> createState() => _LinkedProvidersScreenState();
}

class _LinkedProvidersScreenState extends State<LinkedProvidersScreen> {
  List<Map<String, dynamic>> _providers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAuthProviders();
      if (mounted) setState(() { _providers = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Set<String> get _linkedProviderNames =>
      _providers.map((p) => p['provider'] as String).toSet();

  Future<void> _unlink(int providerId, String providerName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.unlinkProviderConfirmTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.unlinkProviderConfirmBody(providerName),
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel, style: GoogleFonts.poppins(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.unlinkProvider,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.unlinkAuthProvider(providerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signInMethodRemovedPleaseSignInAgain),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await ApiService.logout();
        if (mounted) ApiService.authNotifier.value = false;
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _link(String provider) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      switch (provider) {
        case 'google':
          await ApiService.linkGoogleProvider();
        case 'facebook':
          await ApiService.linkFacebookProvider();
        case 'apple':
          await ApiService.linkAppleProvider();
        default:
          return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.providerLinkedSuccess(_displayName(provider))),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('aborted')) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _displayName(String provider) {
    return switch (provider) {
      'google' => 'Google',
      'facebook' => 'Facebook',
      'apple' => 'Apple',
      _ => provider,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const Divider(height: 1, color: AppColors.divider),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(_error!, style: GoogleFonts.poppins(color: Colors.redAccent)),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    children: [
                      if (_providers.isEmpty)
                        Center(
                          child: Text(
                            l10n.noLinkedProviders,
                            style: GoogleFonts.poppins(color: AppColors.textMuted),
                          ),
                        )
                      else ...[
                        Text(
                          l10n.linkedProviders.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCard(
                          _providers.map((p) {
                            final id = p['id'] as int;
                            final name = _displayName(p['provider'] as String);
                            final email = p['provider_email'] as String?;
                            final isLast = _providers.length == 1;
                            return _ProviderRow(
                              name: name,
                              email: email,
                              canRemove: !isLast,
                              cannotRemoveReason: isLast ? l10n.cannotRemoveLastProvider : null,
                              onRemove: isLast ? null : () => _unlink(id, name),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Text(
                        l10n.linkProvider.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildCard([
                        if (!_linkedProviderNames.contains('google'))
                          _AddRow(name: 'Google', onTap: () => _link('google')),
                        if (!_linkedProviderNames.contains('facebook'))
                          _AddRow(name: 'Facebook', onTap: () => _link('facebook')),
                        if ((Platform.isIOS) && !_linkedProviderNames.contains('apple'))
                          _AddRow(name: 'Apple', onTap: () => _link('apple')),
                        if (_linkedProviderNames.containsAll(_availableProviders()))
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              l10n.providerAlreadyLinked,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _availableProviders() {
    final providers = ['google', 'facebook'];
    if (Platform.isIOS) providers.add('apple');
    return providers;
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.signInMethods,
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

  Widget _buildCard(List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(rows.length, (i) => Column(
          children: [
            rows[i],
            if (i < rows.length - 1)
              const Divider(height: 1, color: AppColors.divider, indent: 56, endIndent: 16),
          ],
        )),
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final String name;
  final String? email;
  final bool canRemove;
  final String? cannotRemoveReason;
  final VoidCallback? onRemove;

  const _ProviderRow({
    required this.name,
    required this.email,
    required this.canRemove,
    this.cannotRemoveReason,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.link_rounded, size: 18, color: AppColors.purple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                if (email != null)
                  Text(email!,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (canRemove)
            TextButton(
              onPressed: onRemove,
              child: Text(
                l10n.unlinkProvider,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600),
              ),
            )
          else
            Tooltip(
              message: cannotRemoveReason ?? '',
              child: Text(
                l10n.unlinkProvider,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _AddRow({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, size: 18, color: AppColors.purple),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
