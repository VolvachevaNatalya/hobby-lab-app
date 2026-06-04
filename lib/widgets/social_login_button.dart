import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SocialLoginButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, child: Center(child: icon)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Brand letter icon used inside SocialLoginButton
class BrandLetterIcon extends StatelessWidget {
  final String letter;
  final Color color;
  final double fontSize;

  const BrandLetterIcon({
    super.key,
    required this.letter,
    required this.color,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
