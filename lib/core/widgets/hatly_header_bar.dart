import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 10),
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
              color: primaryColor.withValues(alpha: 0.15),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: primaryColor,
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
                color: primaryColor,
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
