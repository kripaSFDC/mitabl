import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';

class HomeCookHeaderWidget extends StatelessWidget {
  const HomeCookHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(
              vertical: 0, horizontal: config.AppConfig(context).appWidth(1.5)),
          child: Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: state.cookProfile != null
                      ? "${GlobalConfiguration().getValue<String>('base_url')}/${state.cookProfile!.data!.avatar}"
                      : '',
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Container(
                    height: config.AppConfig(context).appWidth(10),
                    width: config.AppConfig(context).appWidth(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).backgroundColor,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: config.AppConfig(context).appWidth(10),
                    width: config.AppConfig(context).appWidth(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).backgroundColor,
                    ),
                  ),
                  imageBuilder: (context, imageProvider) => Container(
                    height: config.AppConfig(context).appWidth(10),
                    width: config.AppConfig(context).appWidth(10),
                    decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ),
              SizedBox(
                width: config.AppConfig(context).appWidth(3),
              ),
              Expanded(
                child: Text(
                  'Hello, ${state.cookProfile != null ? state.cookProfile!.data!.firstName : ''} ${state.cookProfile != null ? state.cookProfile!.data!.lastName : ''}',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                    fontSize: config.AppConfig(context).appWidth(5.0),
                      ),
                ),
              ),
              Icon(
                Icons.notifications_none_outlined,
                color: config.AppColors().colorPrimary(1),
                size: config.AppConfig(context).appHeight(3),
              ),
            ],
          ),
        );
      },
    );
  }
}
