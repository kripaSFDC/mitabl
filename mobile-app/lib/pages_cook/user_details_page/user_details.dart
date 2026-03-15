import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/star_rating.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../helper/route_arguement.dart';

class UserDetails extends StatelessWidget {
  const UserDetails({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => UserDetails(routeArguments: routeArguments),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        elevation: 0,
        leading: InkWell(
          onTap: () {
            navigatorKey.currentState!.pop();
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).primaryColorDark,
            size: config.AppConfig(context).appWidth(5),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              height: config.AppConfig(context).appHeight(15),
              width: config.AppConfig(context).appHeight(15),
              decoration: const BoxDecoration(
                // color: config.AppColors().textFieldBackgroundColor(1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: CachedNetworkImage(
                imageUrl:
                    '${GlobalConfiguration().getValue<String>('image_base_url')}${routeArguments!.customer!.avatar!}',
                imageBuilder: (context, imageProvider) => Container(
                  height: config.AppConfig(context).appWidth(25),
                  width: config.AppConfig(context).appWidth(25),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),

                errorWidget: (context, data, e) {
                  return Container(
                    height: config.AppConfig(context).appHeight(15),
                    width: config.AppConfig(context).appHeight(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                  );
                },
                placeholder: (context, s) => Container(
                  height: config.AppConfig(context).appHeight(15),
                  width: config.AppConfig(context).appHeight(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: config.AppConfig(context).appHeight(3)),
          Text(
            routeArguments!.customer!.name.toString(),
            style: TextStyle(
              fontSize: config.AppConfig(context).appWidth(4.5),
              color: Theme.of(context).primaryColor,
              fontFamily: config.FontFamily().itcAvantGardeGothicStdFontFamily,
              fontWeight: config.FontFamily().medium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: config.AppConfig(context).appHeight(1)),
          StarRating(
            rating: routeArguments!.customer!.rating!,
            size: config.AppConfig(context).appWidth(5),
            color: const Color(0xffFFA200),
          ),
          SizedBox(height: config.AppConfig(context).appHeight(1)),
          Padding(
            padding: EdgeInsets.all(config.AppConfig(context).appWidth(4)),
            child: Text(
              routeArguments!.customer!.description.toString(),
              style: TextStyle(
                fontSize: config.AppConfig(context).appWidth(4),
                color: Theme.of(context).primaryColorDark,
                fontFamily:
                    config.FontFamily().itcAvantGardeGothicStdFontFamily,
                fontWeight: config.FontFamily().book,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 5,
            ),
          ),
        ],
      ),
    );
  }
}
