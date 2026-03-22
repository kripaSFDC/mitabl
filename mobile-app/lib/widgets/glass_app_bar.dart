import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// A glassmorphism app bar: surface at 80% opacity with 20px backdrop blur.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.height = kToolbarHeight,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double height;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRRect(
      child: BackdropFilter(
        filter: MitablGlass.blur,
        child: Container(
          color: MitablGlass.background,
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: height,
                child: NavigationToolbar(
                  leading: leading ??
                      (ModalRoute.of(context)?.canPop == true
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  size: 20,
                                  color: MitablColors.onSurface),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          : null),
                  middle: title != null
                      ? DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                            fontFamily: 'Nunito',
                          ),
                          child: title!,
                        )
                      : null,
                  trailing: actions != null
                      ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                      : null,
                  centerMiddle: centerTitle,
                  middleSpacing: 16,
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
