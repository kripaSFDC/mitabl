import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/model/bookings.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/helper/route_arguement.dart';

class HomePageCook extends StatefulWidget {
  const HomePageCook({super.key});

  @override
  State<HomePageCook> createState() => _HomePageCookState();
}

class _HomePageCookState extends State<HomePageCook> {
  bool _kitchenLive = true;
  List<Bookings> _queueOrders = [];
  bool _queueLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCookCubit>().getDashBoardData();
    _loadCookingQueue();
  }

  Future<void> _loadCookingQueue() async {
    try {
      final repo = BookingRepository(context.read<UserRepository>());
      final response = await repo.getBookings(
        isUpcoming: true,
        limit: 5,
        page: 1,
      );
      if (response.statusCode == 200) {
        final booking = Booking.fromJson(jsonDecode(response.body));
        if (mounted) {
          setState(() {
            _queueOrders = booking.data?.bookings ?? [];
            _queueLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _queueLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _queueLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MitablColors.surface,
        body: BlocBuilder<DashboardCookCubit, DashboardCookState>(
          builder: (context, state) {
            final dashData = state.dashboardData?.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: MitablSpacing.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Greeting Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Good evening, Chef',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onSurface,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your kitchen overview',
                            style: TextStyle(
                              fontSize: 14,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: MitablColors.primaryContainer,
                        child: const Icon(
                          Icons.person,
                          color: MitablColors.onPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Kitchen Live Toggle ──
                  MitablCard(
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kitchenLive
                                ? MitablColors.accent
                                : MitablColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _kitchenLive
                              ? 'Accepting orders'
                              : 'Kitchen offline',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Kitchen Live',
                          style: TextStyle(
                            fontSize: 13,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _kitchenLive,
                          activeColor: MitablColors.accent,
                          onChanged: (v) => setState(() => _kitchenLive = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: MitablSpacing.listItem),

                  // ── Metric Cards ──
                  Row(
                    children: [
                      Expanded(
                        child: MitablCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 20,
                                    color: MitablColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Active Orders',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${dashData?.nUpcomingBookings ?? 0}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurface,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MitablCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 20,
                                    color: MitablColors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Today's Earnings",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'AUD ${dashData?.totalEarning ?? 0}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurface,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: MitablSpacing.breathe),

                  // ── Cooking Queue Section ──
                  const Text(
                    'Cooking Queue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_queueLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: MitablColors.primary,
                        ),
                      ),
                    )
                  else if (_queueOrders.isEmpty)
                    const MitablCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No active orders in the queue',
                            style: TextStyle(
                              fontSize: 14,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._queueOrders.map((order) {
                      final customerName =
                          order.customer?.name ?? 'Customer';
                      final ticketId =
                          '#${order.orderTypeId ?? order.orderId ?? ''}';
                      final timeLabel =
                          '${order.timeFrom ?? ''} - ${order.timeTo ?? ''}';
                      final itemCount = order.items?.length ?? 0;
                      final itemsSummary = itemCount > 0
                          ? order.items!
                              .take(2)
                              .map((i) => i.food ?? '')
                              .join(', ')
                          : 'Take-away order';
                      final amount =
                          'AUD ${order.itemTotalPrice ?? 0}';

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: MitablSpacing.listItem,
                        ),
                        child: _buildQueueTicket(
                          ticketNumber: ticketId,
                          customerName: customerName,
                          elapsedTime: timeLabel,
                          items: '$itemsSummary • $amount',
                        ),
                      );
                    }),

                  const SizedBox(height: MitablSpacing.breathe),

                  // ── View Revenue Button ──
                  MitablButton(
                    label: 'View Revenue',
                    onPressed: () {
                      navigatorKey.currentState!.pushNamed(
                        '/RevenueAnalytics',
                        arguments: RouteArguments(
                          data: <String, dynamic>{
                            'totalEarning': dashData?.totalEarning ?? 0,
                            'nBookings': dashData?.nBookings ?? 0,
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQueueTicket({
    required String ticketNumber,
    required String customerName,
    required String elapsedTime,
    required String items,
  }) {
    return MitablCard(
      useGhostBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticketNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.primary,
                  fontFamily: 'Nunito',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: MitablColors.secondaryContainer,
                  borderRadius: MitablRadius.pillBorder,
                ),
                child: Text(
                  elapsedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MitablColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MitablColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            items,
            style: const TextStyle(
              fontSize: 13,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MitablButton(
                  label: 'Delay',
                  variant: MitablButtonVariant.outline,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MitablButton(
                  label: 'Mark Ready',
                  variant: MitablButtonVariant.primary,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
