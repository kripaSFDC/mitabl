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
import 'package:mitabl_user/model/top_rated_rest_response.dart';

class TopRatedWidget extends StatelessWidget {
  const TopRatedWidget({Key? key, this.topReatedRestList}) : super(key: key);

  final List<TopReatedRestList>? topReatedRestList;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: config.AppConfig(context).appHeight(13),
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (context, index) {
            return SizedBox(
              width: config.AppConfig(context).appWidth(2),
            );
          },
          itemCount: topReatedRestList!.length,
          itemBuilder: (context, index) {
            return Container(
              width: config.AppConfig(context).appWidth(80),
              decoration: new BoxDecoration(
                borderRadius: new BorderRadius.circular(10.0),
                color: Theme.of(context).primaryColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    Stack(
                      fit: StackFit.loose,
                      alignment: AlignmentDirectional.bottomStart,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: CachedNetworkImage(
                            imageUrl: topReatedRestList!
                                        .elementAt(index)
                                        .images!
                                        .length >
                                    0
                                ? '${GlobalConfiguration().getValue<String>('image_base_url')}${topReatedRestList!.elementAt(index).images![0].path}'
                                : '',
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                    CircularProgressIndicator(
                                        value: downloadProgress.progress),
                            errorWidget: (context, url, error) => Container(
                                height: config.AppConfig(context).appHeight(12),
                                width: config.AppConfig(context).appWidth(26),
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
                              height: config.AppConfig(context).appHeight(12),
                              width: config.AppConfig(context).appWidth(26),
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Column(
                        children: [
                          Flexible(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '${topReatedRestList!.elementAt(index).name}',
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: GoogleFonts.gothicA1(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: config.AppConfig(context)
                                            .appWidth(3.4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '${topReatedRestList!.elementAt(index).address}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    // softWrap: false,
                                    style: GoogleFonts.gothicA1(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: config.AppConfig(context)
                                            .appWidth(2.7)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 4.0, top: 2, bottom: 2, right: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/img/rating_icon.png',
                                        height: config.AppConfig(context)
                                            .appHeight(1.5),
                                        width: config.AppConfig(context)
                                            .appHeight(1.5),
                                        fit: BoxFit.fitHeight,
                                      ),
                                      SizedBox(
                                        width: 2,
                                      ),
                                      Text(
                                        '${topReatedRestList!.elementAt(index).ratingCount!.toStringAsFixed(1)}',
                                        style: GoogleFonts.gothicA1(
                                          fontSize: config.AppConfig(context)
                                              .appWidth(2.7),
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    'assets/img/heart_icon.png',
                                    height: config.AppConfig(context)
                                        .appHeight(1.5),
                                    width: config.AppConfig(context)
                                        .appHeight(1.7),
                                    fit: BoxFit.fitHeight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
