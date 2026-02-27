import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart';

class NearByRestWidget extends StatelessWidget {
  const NearByRestWidget({Key? key, required this.nearByRestaurantsList})
      : super(key: key);
  final NearByRestaurantsList? nearByRestaurantsList;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(2, 2),
            color: config.AppColors().secondColor(1.0),
            blurRadius: 5.0,
          ),
        ],
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Image of the card
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 6.0, top: 6.0),
            child: Stack(
              fit: StackFit.loose,
              alignment: AlignmentDirectional.bottomStart,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: nearByRestaurantsList!.images!.length > 0
                        ? '${GlobalConfiguration().getValue<String>('image_base_url')}${nearByRestaurantsList!.images![0].path}'
                        : '',
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) =>
                            CircularProgressIndicator(
                                value: downloadProgress.progress),
                    errorWidget: (context, url, error) => Container(
                        height: config.AppConfig(context).appHeight(14),
                        width: config.AppConfig(context).appWidth(70),
                        padding: EdgeInsets.all(
                            config.AppConfig(context).appWidth(3)),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: config.AppConfig(context).appWidth(8),
                        )),
                    imageBuilder: (context, imageProvider) => Container(
                      height: config.AppConfig(context).appHeight(14),
                      width: config.AppConfig(context).appWidth(70),
                      decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                  ),
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   crossAxisAlignment: CrossAxisAlignment.end,
                //   children: <Widget>[
                //     Container(
                //         height: 20,
                //         width: 20,
                //         margin: EdgeInsets.only(bottom: 8, right: 4),
                //         child: RawMaterialButton(
                //           onPressed: () {},
                //           elevation: 1.0,
                //           fillColor: config.AppColors().colorPrimary(1.0),
                //           child: const Icon(
                //             Icons.arrow_forward_ios_rounded,
                //             size: 12,
                //             color: Colors.white,
                //           ),
                //           padding: EdgeInsets.all(0.9),
                //           shape: CircleBorder(),
                //         )),
                //   ],
                // ),
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
                          fontSize: config.AppConfig(context).appWidth(3.4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
              ),
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
                      // softWrap: false,
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w600,
                          fontSize: config.AppConfig(context).appWidth(2.7)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
                left: 10.0, top: 2, bottom: 2, right: 10.0),
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
                    SizedBox(
                      width: 2,
                    ),
                    Text(
                      '${nearByRestaurantsList!.ratingCount != null ? nearByRestaurantsList!.ratingCount!.toStringAsFixed(1) : ''}',
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
    );
  }
}
