import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';

class CustomerReviewPage extends StatefulWidget {
  CustomerReviewPage({Key? key, this.routeArguments}) : super(key: key);
  RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => CustomerReviewPage(
              routeArguments: routeArguments,
            ));
  }

  @override
  State<CustomerReviewPage> createState() => _CustomerReviewPageState();
}

class _CustomerReviewPageState extends State<CustomerReviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: config.AppConfig(context).appWidth(50),
        leading: Padding(
          padding: EdgeInsets.only(left: config.AppConfig(context).appWidth(5)),
          child: InkWell(
            onTap: () {
              navigatorKey.currentState!.pop();
            },
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColorDark,
                  size: config.AppConfig(context).appWidth(5),
                ),
                SizedBox(
                  width: config.AppConfig(context).appWidth(2),
                ),
                Text(
                  'Reviews',
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(5),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: config.AppConfig(context).appHeight(2),
          left: config.AppConfig(context).appWidth(5),
          right: config.AppConfig(context).appWidth(5),
        ),
        child: widget.routeArguments!.kitchen!.reviewsData!.isNotEmpty
            ? ListView.separated(
                itemBuilder: (context, index) {
                  return Container(
                    height: config.AppConfig(context).appHeight(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                                  "${GlobalConfiguration().getValue<String>('base_url')}/${widget.routeArguments!.kitchen!.reviewsData![index].user!.avatar}",
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) =>
                                      CircularProgressIndicator(
                                          value: downloadProgress.progress),
                              errorWidget: (context, url, error) => Container(
                                  height:
                                      config.AppConfig(context).appWidth(16),
                                  width: config.AppConfig(context).appWidth(16),
                                  padding: EdgeInsets.all(
                                      config.AppConfig(context).appWidth(3)),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  )),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                height: config.AppConfig(context).appWidth(16),
                                width: config.AppConfig(context).appWidth(16),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(100)),
                              ),
                            ),
                            SizedBox(
                              width: config.AppConfig(context).appWidth(3),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.routeArguments!.kitchen!.reviewsData![index].user!.name!}',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
                                      fontWeight: FontWeight.w400),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                RatingBar.builder(
                                  ignoreGestures: true,
                                  initialRating: widget.routeArguments!.kitchen!
                                      .reviewsData![index].rating!,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize:
                                      config.AppConfig(context).appWidth(5),
                                  itemPadding:
                                      EdgeInsets.symmetric(horizontal: 0),
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: config.AppConfig(context).appWidth(2),
                                  ),
                                  onRatingUpdate: (rating) {
                                    print(rating);
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(1),
                        ),
                        Text(
                          '${widget.routeArguments!.kitchen!.reviewsData![index].review!}',
                          style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: config.AppConfig(context).appWidth(4),
                              fontWeight: FontWeight.w400),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return Divider(
                    height: config.AppConfig(context).appHeight(3),
                    color: Theme.of(context).primaryColorDark,
                  );
                },
                itemCount: widget.routeArguments!.kitchen!.reviewsData!.length)
            : Center(
                child: Text(
                  'No review found.',
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(4.5),
                      fontWeight: FontWeight.w400),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
  }
}
