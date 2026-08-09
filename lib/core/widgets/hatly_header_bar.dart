import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/config/theme.dart';

/// Reusable application header bar with branded logo, title, optional leading widget, and optional trailing action.
class HatlyHeaderBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const HatlyHeaderBar({
    super.key,
    this.title = 'Hatly',
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0x33FFFFFF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
              border: Border.all(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: AppTheme.primaryEmerald,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppTheme.primaryEmerald,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
