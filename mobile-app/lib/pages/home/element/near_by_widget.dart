import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';

class NearByRestWidget extends StatelessWidget {
  const NearByRestWidget({super.key, required this.nearByRestaurantsList});
  final NearByRestaurantsList? nearByRestaurantsList;

  String? _primaryImagePath() {
    final images = nearByRestaurantsList?.images;
    if (images == null || images.isEmpty) {
      return null;
    }

    return images.first.path;
  }

  double _ratingValue() {
    final rawRating = nearByRestaurantsList?.ratingCount;
    if (rawRating is num) {
      return rawRating.toDouble();
    }

    return double.tryParse(rawRating?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final kitchenId = nearByRestaurantsList?.id;
    return InkWell(
      onTap: kitchenId == null
          ? null
          : () => Navigator.of(context).pushNamed(
              '/OrderMenu',
              arguments: RouteArguments(
                data: OrderRouteData(kitchenId: kitchenId),
              ),
            ),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          boxShadow: [
            BoxShadow(
              offset: const Offset(2, 2),
              color: config.AppColors().secondColor(1.0),
              blurRadius: 5.0,
            ),
          ],
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6.0, top: 6.0),
              child: Stack(
                fit: StackFit.loose,
                alignment: AlignmentDirectional.bottomStart,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: CachedNetworkImage(
                      imageUrl: _primaryImagePath() != null
                          ? '${GlobalConfiguration().getValue<String>('image_base_url')}${_primaryImagePath()}'
                          : '',
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) =>
                              CircularProgressIndicator(
                                value: downloadProgress.progress,
                              ),
                      errorWidget: (context, url, error) => Container(
                        height: config.AppConfig(context).appHeight(14),
                        width: config.AppConfig(context).appWidth(70),
                        padding: EdgeInsets.all(
                          config.AppConfig(context).appWidth(3),
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        child: Icon(
                          Icons.person,
                          color: const Color(0xFFFFFFFF),
                          size: config.AppConfig(context).appWidth(8),
                        ),
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        height: config.AppConfig(context).appHeight(14),
                        width: config.AppConfig(context).appWidth(70),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${nearByRestaurantsList?.name}',
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w600,
                          fontSize: config.AppConfig(context).appWidth(3.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${nearByRestaurantsList?.address}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w600,
                          fontSize: config.AppConfig(context).appWidth(2.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                top: 2,
                bottom: 2,
                right: 10.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/img/rating_icon.png',
                        height: config.AppConfig(context).appHeight(1.5),
                        width: config.AppConfig(context).appHeight(1.5),
                        fit: BoxFit.fitHeight,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _ratingValue().toStringAsFixed(1),
                        style: GoogleFonts.gothicA1(
                          fontSize: config.AppConfig(context).appWidth(2.7),
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    'assets/img/heart_icon.png',
                    height: config.AppConfig(context).appHeight(1.5),
                    width: config.AppConfig(context).appHeight(1.5),
                    fit: BoxFit.fitHeight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
