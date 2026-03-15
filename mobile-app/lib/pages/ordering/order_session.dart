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
  bool isLoadingDineInSlots = false;
  bool isRefreshingMenu = false;
  String? errorMessage;
  String? dineInSlotError;
  OrderKitchenSummary? kitchen;
  List<OrderMenuItem> menuItems = const <OrderMenuItem>[];
  List<DineInSlotOption> dineInSlots = const <DineInSlotOption>[];
  final Map<int, CartLineItem> _cartItems = <int, CartLineItem>{};
  OrderServiceType? serviceType;
  int? selectedDineInSlotId;
  int _dineInSlotRequestVersion = 0;
  int _menuRequestVersion = 0;
  bool _isDisposed = false;
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

  DineInSlotOption? get selectedDineInSlot {
    final selectedId = selectedDineInSlotId;
    if (selectedId == null) {
      return null;
    }

    for (final slot in dineInSlots) {
      if (slot.id == selectedId) {
        return slot;
      }
    }

    return null;
  }

  bool get canCheckout =>
      kitchen != null &&
      serviceType != null &&
      _cartItems.isNotEmpty &&
      (serviceType != OrderServiceType.dineIn || selectedDineInSlot != null);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final (loadedKitchen, _) = await repository.fetchKitchen(kitchenId);
      kitchen = loadedKitchen;
      dineInSlots = loadedKitchen.dineInSlots
          .where((slot) => slot.matchesDate(scheduledDate))
          .toList(growable: false);
      serviceType ??= loadedKitchen.takeAwayAvailable
          ? OrderServiceType.takeAway
          : loadedKitchen.dineInAvailable
              ? OrderServiceType.dineIn
              : null;
      if (serviceType == null) {
        errorMessage = 'This kitchen is not currently accepting orders.';
      }
      await _refreshDineInSlotsIfNeeded(notify: false);
      if (serviceType != OrderServiceType.dineIn) {
        await _refreshMenuAvailability(notify: false);
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
    if (nextType != OrderServiceType.dineIn) {
      _dineInSlotRequestVersion++;
      isLoadingDineInSlots = false;
      dineInSlotError = null;
      selectedDineInSlotId = null;
    }
    _removeUnavailableCartLines();
    notifyListeners();
    if (nextType == OrderServiceType.dineIn) {
      _refreshDineInSlotsIfNeeded();
      return;
    }

    _refreshMenuAvailability();
  }

  void updateScheduledDate(DateTime date) {
    scheduledDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    if (serviceType == OrderServiceType.dineIn) {
      _refreshDineInSlotsIfNeeded();
      return;
    }

    _refreshMenuAvailability();
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

    if (serviceType == OrderServiceType.dineIn) {
      return;
    }

    scheduledTime = next;
    notifyListeners();
    _refreshMenuAvailability();
  }

  void updatePersons(int value) {
    persons = value.clamp(1, 20).toInt();
    notifyListeners();
    _refreshDineInSlotsIfNeeded();
  }

  void selectDineInSlot(int? slotId) {
    selectedDineInSlotId = slotId;
    _syncScheduledTimeToSelectedSlot();
    notifyListeners();
    _refreshMenuAvailability();
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
    if (serviceType == OrderServiceType.dineIn && selectedDineInSlot == null) {
      throw StateError('Please choose an available dine-in slot.');
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
        dineInSlotId: serviceType == OrderServiceType.dineIn
            ? selectedDineInSlotId
            : null,
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

  bool isItemAvailable(OrderMenuItem item) =>
      _isItemAvailableForCurrentService(item);

  void _removeUnavailableCartLines() {
    final currentType = serviceType;
    if (currentType == null) {
      return;
    }

    final visibleIds = menuItems.map((item) => item.id).toSet();
    _cartItems.removeWhere(
      (_, line) =>
          !visibleIds.contains(line.item.id) ||
          !_isItemAvailableForCurrentService(line.item),
    );
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

  Future<void> _refreshDineInSlotsIfNeeded({bool notify = true}) async {
    final currentKitchen = kitchen;
    if (currentKitchen == null ||
        serviceType != OrderServiceType.dineIn ||
        !currentKitchen.dineInAvailable) {
      return;
    }

    final requestVersion = ++_dineInSlotRequestVersion;
    isLoadingDineInSlots = true;
    dineInSlotError = null;
    if (notify) {
      notifyListeners();
    }

    try {
      final slots = await repository.fetchDineInSlots(
        kitchenId: currentKitchen.id,
        date: DateFormat('yyyy-MM-dd').format(scheduledDate),
        persons: persons,
      );
      if (!_shouldApplyDineInSlotResponse(requestVersion, currentKitchen.id)) {
        return;
      }
      dineInSlots =
          slots.where((slot) => slot.isAvailable).toList(growable: false);

      final selectedId = selectedDineInSlotId;
      if (selectedId == null ||
          !dineInSlots.any((slot) => slot.id == selectedId)) {
        selectedDineInSlotId =
            dineInSlots.isEmpty ? null : dineInSlots.first.id;
      }

      if (dineInSlots.isEmpty) {
        dineInSlotError =
            'No dine-in tables are available for this date and party size.';
      }

      _syncScheduledTimeToSelectedSlot();
      await _refreshMenuAvailability(notify: false);
    } catch (error) {
      if (!_shouldApplyDineInSlotResponse(requestVersion, currentKitchen.id)) {
        return;
      }
      dineInSlots = currentKitchen.dineInSlots
          .where((slot) => slot.matchesDate(scheduledDate) && slot.status == 1)
          .toList(growable: false);
      final selectedId = selectedDineInSlotId;
      if (selectedId == null ||
          !dineInSlots.any((slot) => slot.id == selectedId)) {
        selectedDineInSlotId =
            dineInSlots.isEmpty ? null : dineInSlots.first.id;
      }
      dineInSlotError = dineInSlots.isEmpty
          ? error.toString()
          : 'Live slot availability could not be refreshed. Showing scheduled slots.';
      _syncScheduledTimeToSelectedSlot();
      await _refreshMenuAvailability(notify: false);
    } finally {
      if (_shouldApplyDineInSlotResponse(requestVersion, currentKitchen.id)) {
        isLoadingDineInSlots = false;
        notifyListeners();
      }
    }
  }

  Future<void> _refreshMenuAvailability({bool notify = true}) async {
    final currentKitchen = kitchen;
    final currentType = serviceType;
    if (currentKitchen == null || currentType == null) {
      return;
    }

    final requestVersion = ++_menuRequestVersion;
    isRefreshingMenu = true;
    if (notify) {
      notifyListeners();
    }

    try {
      final refreshedMenu = await repository.fetchMenu(
        kitchenId: currentKitchen.id,
        deliveryDate: DateFormat('yyyy-MM-dd').format(scheduledDate),
        deliveryTimeFrom: scheduledTime.startApiValue,
        deliveryTimeTo: scheduledTime.endApiValue,
        serviceType: currentType,
      );

      if (!_shouldApplyMenuResponse(requestVersion, currentKitchen.id)) {
        return;
      }

      menuItems = refreshedMenu;
      errorMessage = null;
      _removeUnavailableCartLines();
    } catch (error) {
      if (!_shouldApplyMenuResponse(requestVersion, currentKitchen.id)) {
        return;
      }

      errorMessage = error.toString();
    } finally {
      if (_shouldApplyMenuResponse(requestVersion, currentKitchen.id)) {
        isRefreshingMenu = false;
        notifyListeners();
      }
    }
  }

  void _syncScheduledTimeToSelectedSlot() {
    final slot = selectedDineInSlot;
    if (slot == null) {
      return;
    }

    scheduledTime = TimeOfDayRange.fromApiRange(
      start: slot.startTime,
      end: slot.endTime,
    );
  }

  bool _shouldApplyDineInSlotResponse(int requestVersion, int kitchenId) {
    return !_isDisposed &&
        requestVersion == _dineInSlotRequestVersion &&
        kitchen?.id == kitchenId &&
        serviceType == OrderServiceType.dineIn;
  }

  bool _shouldApplyMenuResponse(int requestVersion, int kitchenId) {
    return !_isDisposed &&
        requestVersion == _menuRequestVersion &&
        kitchen?.id == kitchenId;
  }

  @override
  void notifyListeners() {
    if (_isDisposed) {
      return;
    }

    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

  factory TimeOfDayRange.fromApiRange({
    required String start,
    required String end,
  }) {
    final startParts = start.split(':');
    final endParts = end.split(':');

    return TimeOfDayRange(
      startHour: int.tryParse(startParts.isNotEmpty ? startParts[0] : '') ?? 0,
      startMinute:
          int.tryParse(startParts.length > 1 ? startParts[1] : '') ?? 0,
      endHour: int.tryParse(endParts.isNotEmpty ? endParts[0] : '') ?? 0,
      endMinute: int.tryParse(endParts.length > 1 ? endParts[1] : '') ?? 0,
    );
  }

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
