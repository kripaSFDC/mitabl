import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/model/recommended_rest_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/helper.dart';

class RecommendedRestWidget extends StatefulWidget {
  const RecommendedRestWidget({Key? key, this.recommendedResturant})
      : super(key: key);
  final RecommendedResturant? recommendedResturant;

  @override
  _RecommendedRestWidgetState createState() => _RecommendedRestWidgetState();
}

class _RecommendedRestWidgetState extends State<RecommendedRestWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 5.0),
        width: config.AppConfig(context).appWidth(100.0),
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
        child: Stack(
          children: [
            Column(
              children: [
                Stack(
                  fit: StackFit.loose,
                  alignment: AlignmentDirectional.bottomStart,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      child: CachedNetworkImage(
                        imageUrl: widget.recommendedResturant!.images!.length >
                                0
                            ? '${GlobalConfiguration().getValue<String>('image_base_url')}${widget.recommendedResturant!.images![0].path}'
                            : '',
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                        errorWidget: (context, url, error) => Container(
                            height: config.AppConfig(context).appHeight(17),
                            width: config.AppConfig(context).appWidth(100),
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
                          height: config.AppConfig(context).appHeight(16),
                          width: config.AppConfig(context).appWidth(100),
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10))),
                        ),
                      ),
                    ),
                  ],
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
                            '${widget.recommendedResturant?.name}',
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColorDark,
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    config.AppConfig(context).appWidth(3.4)),
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
                            '${widget.recommendedResturant?.address}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            // softWrap: false,
                            style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColorDark,
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    config.AppConfig(context).appWidth(2.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
                left: 1,
                bottom: 1,
                right: 1,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, top: 2, bottom: 6, right: 10.0),
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
                            '${widget.recommendedResturant!.ratingCount!.toStringAsFixed(1)}',
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
                        width: config.AppConfig(context).appHeight(1.8),
                        fit: BoxFit.fitHeight,
                        color: Theme.of(context).hintColor,
                      ),
                    ],
                  ),
                ))
          ],
        ));
  }
}
