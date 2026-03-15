import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/model/top_rated_rest_response.dart';

class TopRatedWidget extends StatefulWidget {
  const TopRatedWidget({
    super.key,
    this.topReatedRestList,
    this.onLoadMore,
    this.canLoadMore = false,
    this.isLoadingMore = false,
  });

  final List<TopReatedRestList>? topReatedRestList;
  final Future<void> Function()? onLoadMore;
  final bool canLoadMore;
  final bool isLoadingMore;

  @override
  State<TopRatedWidget> createState() => _TopRatedWidgetState();
}

class _TopRatedWidgetState extends State<TopRatedWidget> {
  late final ScrollController _scrollController;

  String? _primaryImagePath(TopReatedRestList item) {
    final images = item.images;
    if (images == null || images.isEmpty) {
      return null;
    }

    return images.first.path;
  }

  double _ratingValue(dynamic rawRating) {
    if (rawRating is num) {
      return rawRating.toDouble();
    }

    return double.tryParse(rawRating?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    _scrollController = ScrollController()..addListener(_handleScroll);
    super.initState();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        !widget.canLoadMore ||
        widget.isLoadingMore ||
        widget.onLoadMore == null) {
      return;
    }

    if (_scrollController.position.extentAfter < 200) {
      widget.onLoadMore!.call();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.topReatedRestList ?? const <TopReatedRestList>[];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: config.AppConfig(context).appHeight(13),
      child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          separatorBuilder: (context, index) {
            return SizedBox(
              width: config.AppConfig(context).appWidth(2),
            );
          },
          itemCount: items.length + (widget.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return SizedBox(
                width: config.AppConfig(context).appWidth(20),
                child: const Center(
                  child: CupertinoActivityIndicator(color: Colors.grey),
                ),
              );
            }

            final item = items.elementAt(index);
            return InkWell(
              onTap: item.id == null
                  ? null
                  : () => Navigator.of(context).pushNamed(
                        '/OrderMenu',
                        arguments: RouteArguments(
                          data: OrderRouteData(kitchenId: item.id),
                        ),
                      ),
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                width: config.AppConfig(context).appWidth(80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
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
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: CachedNetworkImage(
                              imageUrl: _primaryImagePath(item) != null
                                  ? '${GlobalConfiguration().getValue<String>('image_base_url')}${_primaryImagePath(item)}'
                                  : '',
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) =>
                                      CircularProgressIndicator(
                                          value: downloadProgress.progress),
                              errorWidget: (context, url, error) => Container(
                                  height:
                                      config.AppConfig(context).appHeight(12),
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
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                height: config.AppConfig(context).appHeight(12),
                                width: config.AppConfig(context).appWidth(26),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10))),
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
                                        '${item.name}',
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
                                        '${item.address}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                              const Spacer(),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4.0,
                                      top: 2,
                                      bottom: 2,
                                      right: 4.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/img/rating_icon.png',
                                            height: config.AppConfig(context)
                                                .appHeight(1.5),
                                            width: config.AppConfig(context)
                                                .appHeight(1.5),
                                            fit: BoxFit.fitHeight,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            _ratingValue(
                                              item.ratingCount,
                                            ).toStringAsFixed(1),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }
}
