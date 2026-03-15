import 'dart:convert';

enum OrderServiceType { dineIn, takeAway }

class OrderKitchenSummary {
  OrderKitchenSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.dineInAvailable,
    required this.takeAwayAvailable,
    this.description,
    this.images = const <String>[],
    this.rating,
    this.gstEnabled = false,
    this.gstAmount = 0,
  });

  final int id;
  final String name;
  final String address;
  final bool dineInAvailable;
  final bool takeAwayAvailable;
  final String? description;
  final List<String> images;
  final double? rating;
  final bool gstEnabled;
  final int gstAmount;

  factory OrderKitchenSummary.fromJson(Map<String, dynamic> json) {
    final dynamic gst = json['gst'];
    final List<String> images = ((json['images'] as List?) ?? const [])
        .map((dynamic image) => image?.toString() ?? '')
        .where((path) => path.isNotEmpty)
        .toList(growable: false);

    return OrderKitchenSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Kitchen',
      address: json['address']?.toString() ?? '',
      dineInAvailable: (json['dine_in'] as num?)?.toInt() == 1,
      takeAwayAvailable: (json['take_away'] as num?)?.toInt() == 1,
      description: json['description']?.toString(),
      images: images,
      rating: (json['rating_count'] as num?)?.toDouble(),
      gstEnabled: gst is Map<String, dynamic> &&
          (gst['gst_enable'] as num?)?.toInt() == 1,
      gstAmount: gst is Map<String, dynamic>
          ? (gst['gst_amount'] as num?)?.toInt() ?? 0
          : 0,
    );
  }
}

class OrderMenuItem {
  OrderMenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.dineInAvailable,
    required this.takeAwayAvailable,
    this.description,
    this.images = const <String>[],
  });

  final int id;
  final int restaurantId;
  final String name;
  final double price;
  final bool dineInAvailable;
  final bool takeAwayAvailable;
  final String? description;
  final List<String> images;

  factory OrderMenuItem.fromJson(Map<String, dynamic> json) {
    final rawPictures = json['pictures'];
    final List<String> images = rawPictures is List
        ? rawPictures
            .map((dynamic image) => image?.toString() ?? '')
            .where((path) => path.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return OrderMenuItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      restaurantId: (json['restaurant_id'] as num?)?.toInt() ?? 0,
      name: json['food_name']?.toString() ?? 'Menu item',
      price: (json['price'] as num?)?.toDouble() ??
          double.tryParse(json['price']?.toString() ?? '') ??
          0,
      dineInAvailable: (json['dine_in'] as num?)?.toInt() != 0,
      takeAwayAvailable: (json['take_away'] as num?)?.toInt() != 0,
      description: json['description']?.toString(),
      images: images,
    );
  }
}

class CartLineItem {
  CartLineItem({
    required this.item,
    required this.quantity,
  });

  final OrderMenuItem item;
  final int quantity;

  double get lineTotal => item.price * quantity;

  CartLineItem copyWith({
    OrderMenuItem? item,
    int? quantity,
  }) {
    return CartLineItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}

class OrderSubmissionResult {
  OrderSubmissionResult({
    required this.orderId,
    required this.totalPrice,
    required this.message,
  });

  final int orderId;
  final String totalPrice;
  final String message;

  factory OrderSubmissionResult.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload =
        data is Map<String, dynamic> ? data : <String, dynamic>{};
    return OrderSubmissionResult(
      orderId: (payload['order_id'] as num?)?.toInt() ?? 0,
      totalPrice: payload['total_price']?.toString() ?? '0.00',
      message: json['message']?.toString() ?? 'Order placed.',
    );
  }
}

String encodeOrderItems(List<CartLineItem> lines) {
  return jsonEncode(lines
      .map((line) => {
            'id': line.item.id,
            'quantity': line.quantity,
          })
      .toList(growable: false));
}

