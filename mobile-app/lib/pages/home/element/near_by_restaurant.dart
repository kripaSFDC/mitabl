import 'package:flutter/cupertino.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart';
import 'package:mitabl_user/pages/home/element/near_by_widget.dart';

class NearByRestaurants extends StatefulWidget {
  const NearByRestaurants({Key? key, required this.nearByRestaurantsList})
      : super(key: key);

  final List<NearByRestaurantsList>? nearByRestaurantsList;

  @override
  _NearByRestaurantsState createState() => _NearByRestaurantsState();
}

class _NearByRestaurantsState extends State<NearByRestaurants> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          primary: false,
          crossAxisSpacing: 14,
          childAspectRatio: 0.9,
          mainAxisSpacing: 14,
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 4, top: 4),
          crossAxisCount:
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? 2
                  : 4,
          // Generate 100 widgets that display their index in the List.
          children:
              List.generate(widget.nearByRestaurantsList?.length ?? 0, (index) {
            return Container(
              child: NearByRestWidget(
                nearByRestaurantsList:
                    widget.nearByRestaurantsList!.elementAt(index),
              ),
            );
          }),
        ),
      ],
    );
  }
}
