import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/repos/ordering_repository.dart';

class OrderRouteData {
  OrderRouteData({
    this.kitchenId,
    this.session,
  });

  final int? kitchenId;
  final OrderSessionController? session;
}

class OrderSessionController extends ChangeNotifier {
  OrderSessionController({
    required this.repository,
    required this.kitchenId,
  }) {
    final now = DateTime.now();
    scheduledDate =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  final OrderingRepository repository;
  final int kitchenId;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  OrderKitchenSummary? kitchen;
  List<OrderMenuItem> menuItems = const <OrderMenuItem>[];
  final Map<int, CartLineItem> _cartItems = <int, CartLineItem>{};
  OrderServiceType? serviceType;
  late DateTime scheduledDate;
  TimeOfDayRange scheduledTime = const TimeOfDayRange(
    startHour: 12,
    startMinute: 0,
    endHour: 13,
    endMinute: 0,
  );
  int persons = 2;
  OrderSubmissionResult? submissionResult;
  OrderPaymentSelection? paymentSelection;

  List<CartLineItem> get cartItems => _cartItems.values.toList(growable: false);

  int get totalItems =>
      _cartItems.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get itemTotal =>
      _cartItems.values.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get taxTotal {
    final currentKitchen = kitchen;
    if (currentKitchen == null ||
        !currentKitchen.gstEnabled ||
        currentKitchen.gstAmount <= 0) {
      return 0;
    }

    return _roundMoney(itemTotal * (currentKitchen.gstAmount / 100));
  }

  double get estimatedTotal => _roundMoney(itemTotal + taxTotal);

  bool get canCheckout =>
      kitchen != null && serviceType != null && _cartItems.isNotEmpty;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final (loadedKitchen, loadedMenu) = await repository.fetchKitchen(kitchenId);
      kitchen = loadedKitchen;
      menuItems = loadedMenu;
      serviceType ??= loadedKitchen.takeAwayAvailable
          ? OrderServiceType.takeAway
          : loadedKitchen.dineInAvailable
              ? OrderServiceType.dineIn
              : null;
      if (serviceType == null) {
        errorMessage = 'This kitchen is not currently accepting orders.';
      }
      _removeUnavailableCartLines();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void addItem(OrderMenuItem item) {
    if (!_isItemAvailableForCurrentService(item)) {
      return;
    }

    final existing = _cartItems[item.id];
    _cartItems[item.id] = existing == null
        ? CartLineItem(item: item, quantity: 1)
        : existing.copyWith(quantity: existing.quantity + 1);
    notifyListeners();
  }

  void removeItem(OrderMenuItem item) {
    final existing = _cartItems[item.id];
    if (existing == null) {
      return;
    }

    if (existing.quantity <= 1) {
      _cartItems.remove(item.id);
    } else {
      _cartItems[item.id] = existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
  }

  int quantityFor(OrderMenuItem item) => _cartItems[item.id]?.quantity ?? 0;

  void selectServiceType(OrderServiceType nextType) {
    if (kitchen == null) {
      serviceType = nextType;
      notifyListeners();
      return;
    }

    if (nextType == OrderServiceType.dineIn && !kitchen!.dineInAvailable) {
      return;
    }
    if (nextType == OrderServiceType.takeAway && !kitchen!.takeAwayAvailable) {
      return;
    }

    serviceType = nextType;
    _removeUnavailableCartLines();
    notifyListeners();
  }

  void updateScheduledDate(DateTime date) {
    scheduledDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void updateTime({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    final next = TimeOfDayRange(
      startHour: startHour ?? scheduledTime.startHour,
      startMinute: startMinute ?? scheduledTime.startMinute,
      endHour: endHour ?? scheduledTime.endHour,
      endMinute: endMinute ?? scheduledTime.endMinute,
    );

    if (!next.isValid) {
      return;
    }

    scheduledTime = next;
    notifyListeners();
  }

  void updatePersons(int value) {
    persons = value.clamp(1, 20).toInt();
    notifyListeners();
  }

  void selectPayment(OrderPaymentSelection selection) {
    paymentSelection = selection.isBlank ? null : selection;
    notifyListeners();
  }

  void clearPaymentSelection() {
    paymentSelection = null;
    notifyListeners();
  }

  Future<OrderSubmissionResult> submit() async {
    if (kitchen == null || serviceType == null || _cartItems.isEmpty) {
      throw StateError('Order is incomplete.');
    }
    if (paymentSelection == null || paymentSelection!.isBlank) {
      throw StateError('Payment method is incomplete.');
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final orderResult = await repository.placeOrder(
        kitchenId: kitchen!.id,
        deliveryDate: DateFormat('yyyy-MM-dd').format(scheduledDate),
        deliveryTimeFrom: scheduledTime.startApiValue,
        deliveryTimeTo: scheduledTime.endApiValue,
        serviceType: serviceType!,
        items: cartItems,
        persons: serviceType == OrderServiceType.dineIn ? persons : null,
        taxes: taxTotal,
        paymentSelection: paymentSelection,
      );

      submissionResult = orderResult;
      _cartItems.clear();
      notifyListeners();
      return orderResult;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  bool isItemAvailable(OrderMenuItem item) => _isItemAvailableForCurrentService(item);

  void _removeUnavailableCartLines() {
    final currentType = serviceType;
    if (currentType == null) {
      return;
    }

    _cartItems.removeWhere((_, line) => !_isItemAvailableForCurrentService(line.item));
  }

  bool _isItemAvailableForCurrentService(OrderMenuItem item) {
    final currentType = serviceType;
    if (currentType == null) {
      return false;
    }

    return currentType == OrderServiceType.dineIn
        ? item.dineInAvailable
        : item.takeAwayAvailable;
  }

  double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

class TimeOfDayRange {
  const TimeOfDayRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  bool get isValid {
    final startTotal = (startHour * 60) + startMinute;
    final endTotal = (endHour * 60) + endMinute;
    return endTotal > startTotal;
  }

  String get startApiValue => _toApiValue(startHour, startMinute);

  String get endApiValue => _toApiValue(endHour, endMinute);

  String get startLabel => _toLabel(startHour, startMinute);

  String get endLabel => _toLabel(endHour, endMinute);

  static String _toApiValue(int hour, int minute) {
    final normalizedHour = hour.toString().padLeft(2, '0');
    final normalizedMinute = minute.toString().padLeft(2, '0');
    return '$normalizedHour:$normalizedMinute';
  }

  static String _toLabel(int hour, int minute) {
    final date = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(date);
  }
}
