import 'dart:convert';

enum OrderServiceType { dineIn, takeAway }

enum CheckoutPaymentMode { savedCard, oneTimePaymentMethod }

class OrderKitchenSummary {
  OrderKitchenSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.dineInAvailable,
    required this.takeAwayAvailable,
    this.description,
    this.images = const <String>[],
    this.dineInSlots = const <DineInSlotOption>[],
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
  final List<DineInSlotOption> dineInSlots;
  final double? rating;
  final bool gstEnabled;
  final int gstAmount;

  factory OrderKitchenSummary.fromJson(Map<String, dynamic> json) {
    final dynamic gst = json['gst'];
    final List<String> images = ((json['images'] as List?) ?? const [])
        .map((dynamic image) => image?.toString() ?? '')
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final rawDineInSlots = json['dine_in_slots'];
    final List<DineInSlotOption> dineInSlots = rawDineInSlots is List
        ? rawDineInSlots
            .whereType<Map>()
            .map((slot) =>
                DineInSlotOption.fromJson(Map<String, dynamic>.from(slot)))
            .toList(growable: false)
        : const <DineInSlotOption>[];

    return OrderKitchenSummary(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? 'Kitchen',
      address: json['address']?.toString() ?? '',
      dineInAvailable: _asInt(json['dine_in']) == 1,
      takeAwayAvailable: _asInt(json['take_away']) == 1,
      description: json['description']?.toString(),
      images: images,
      dineInSlots: dineInSlots,
      rating: _asDoubleOrNull(json['rating_count']),
      gstEnabled: gst is Map<String, dynamic> && _asInt(gst['gst_enable']) == 1,
      gstAmount: gst is Map<String, dynamic> ? _asInt(gst['gst_amount']) : 0,
    );
  }
}

class DineInSlotOption {
  DineInSlotOption({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isAvailable,
    this.dayName,
    this.deliveryDate,
    this.seatCapacity,
    this.bookedSeats,
    this.remainingSeats,
  });

  final int id;
  final int dayOfWeek;
  final String? dayName;
  final String? deliveryDate;
  final String startTime;
  final String endTime;
  final int? seatCapacity;
  final int? bookedSeats;
  final int? remainingSeats;
  final int status;
  final bool isAvailable;

  factory DineInSlotOption.fromJson(Map<String, dynamic> json) {
    return DineInSlotOption(
      id: _asInt(json['id']),
      dayOfWeek: _asInt(json['day_of_week']),
      dayName: json['day_name']?.toString(),
      deliveryDate: json['delivery_date']?.toString(),
      startTime: _normalizeTime(json['start_time']),
      endTime: _normalizeTime(json['end_time']),
      seatCapacity:
          json['seat_capacity'] == null ? null : _asInt(json['seat_capacity']),
      bookedSeats:
          json['booked_seats'] == null ? null : _asInt(json['booked_seats']),
      remainingSeats: json['remaining_seats'] == null
          ? null
          : _asInt(json['remaining_seats']),
      status: _asInt(json['status']),
      isAvailable: json['is_available'] == null
          ? _asInt(json['status']) == 1
          : json['is_available'] == true ||
              json['is_available']?.toString() == '1',
    );
  }

  String get startLabel => _timeToLabel(startTime);

  String get endLabel => _timeToLabel(endTime);

  bool matchesDate(DateTime date) => dayOfWeek == (date.weekday % 7);
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
      id: _asInt(json['id']),
      restaurantId: _asInt(json['restaurant_id']),
      name: json['food_name']?.toString() ?? 'Menu item',
      price: _asDouble(json['price']),
      dineInAvailable: _asInt(json['dine_in']) != 0,
      takeAwayAvailable: _asInt(json['take_away']) != 0,
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
    this.paymentId,
    this.paymentIntentId,
    this.paymentMethodId,
  });

  final int orderId;
  final String totalPrice;
  final String message;
  final int? paymentId;
  final String? paymentIntentId;
  final String? paymentMethodId;

  factory OrderSubmissionResult.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload =
        data is Map<String, dynamic> ? data : <String, dynamic>{};
    return OrderSubmissionResult(
      orderId: (payload['order_id'] as num?)?.toInt() ?? 0,
      totalPrice: payload['total_price']?.toString() ?? '0.00',
      message: json['message']?.toString() ?? 'Order placed.',
      paymentId: (payload['payment_id'] as num?)?.toInt(),
      paymentIntentId: payload['payment_intent_id']?.toString(),
      paymentMethodId: payload['payment_method_id']?.toString(),
    );
  }
}

class OrderPaymentSelection {
  const OrderPaymentSelection.savedCard(this.reference)
      : mode = CheckoutPaymentMode.savedCard;

  const OrderPaymentSelection.oneTime(this.reference)
      : mode = CheckoutPaymentMode.oneTimePaymentMethod;

  final CheckoutPaymentMode mode;
  final String reference;

  bool get isBlank => reference.trim().isEmpty;
}

String encodeOrderItems(List<CartLineItem> lines) {
  return jsonEncode(lines
      .map((line) => {
            'id': line.item.id,
            'quantity': line.quantity,
          })
      .toList(growable: false));
}

String _normalizeTime(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.length >= 5) {
    return raw.substring(0, 5);
  }

  return raw;
}

String _timeToLabel(String value) {
  final parts = value.split(':');
  if (parts.length < 2) {
    return value;
  }

  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final period = hour >= 12 ? 'PM' : 'AM';
  final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
  final normalizedMinute = minute.toString().padLeft(2, '0');

  return '$normalizedHour:$normalizedMinute $period';
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDoubleOrNull(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}
