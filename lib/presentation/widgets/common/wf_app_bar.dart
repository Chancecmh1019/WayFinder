import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WfAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final List<Widget>? actions;
  final String? backLabel;

  const WfAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.actions,
    this.backLabel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    final bg = isDark ? AppTheme.pureBlack : AppTheme.offWhite;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_left_rounded,
                      size: 28, color: fg),
                  if (backLabel != null)
                    Text(
                      backLabel!,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyChinese,
                        fontSize: 17,
                        color: fg,
                        fontWeight: AppTheme.weightRegular,
                        letterSpacing: -0.3,
                      ),
                    ),
                ],
              ),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamilyChinese,
                fontSize: 17,
                fontWeight: AppTheme.weightSemiBold,
                color: fg,
                letterSpacing: -0.4,
              ),
            )
          : null,
      actions: actions,
    );
  }
}
