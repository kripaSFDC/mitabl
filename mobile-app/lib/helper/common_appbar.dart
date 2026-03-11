import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar(
      {super.key, this.title = '', this.isFilter = true, this.onFilterSelected});

  final String? title;
  final bool? isFilter;
  final VoidCallback? onFilterSelected;

  // You also need to override the preferredSize attribute.
  // You can set it to kToolbarHeight to get the default appBar height.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: Padding(
        padding: EdgeInsets.only(top: config.AppConfig(context).appHeight(0.5)),
        child: Text(
          title!,
          maxLines: 1,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: config.AppConfig(context).appWidth(5.0),
              ),
        ),
      ),
      elevation: 0,
      iconTheme: IconThemeData(color: config.AppColors().colorPrimaryDark(1)),
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          CupertinoIcons.back,
          size: 30,
        ),
      ),
      actions: [
        isFilter!
            ? IconButton(
                onPressed: () => onFilterSelected!(),
                icon: SvgPicture.asset(
                  'assets/img/filter.svg',
                  height: config.AppConfig(context).appHeight(2.0),
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              )
            : Container()
      ],
    );
  }
}
