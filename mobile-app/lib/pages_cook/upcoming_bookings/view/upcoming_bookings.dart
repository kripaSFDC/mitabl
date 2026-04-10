import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/pages_cook/bookings/cubit/bookings_cubit.dart';
import 'package:mitabl_user/pages_cook/bookings/elements/booking_filter_dialog.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';
import '../../bookings/elements/order_details_booking.dart';

class UpcomingBookings extends StatefulWidget {
  const UpcomingBookings({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) =>
            BookingsCubit(BookingRepository(context.read<UserRepository>())),
        child: const UpcomingBookings(),
      ),
    );
  }

  @override
  State<UpcomingBookings> createState() => _UpcomingBookingsState();
}

class _UpcomingBookingsState extends State<UpcomingBookings> {
  int _selectedFilter = 0; // 0=All, 1=Dine-in, 2=Take-away

  @override
  void initState() {
    super.initState();
    context.read<BookingsCubit>().onStatusChanged(data: '');
    context.read<BookingsCubit>().onSortByChanged(data: '');
    context.read<BookingsCubit>().getUpcomingBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: BlocConsumer<BookingsCubit, BookingsState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state.upcomingBookingStatus!.isSubmissionInProgress) {
            return const Center(child: CommonProgressWidget());
          }
          if (state.upcomingBookingModel == null ||
              state.upcomingBookingModel!.data!.bookings!.isEmpty) {
            return const NoDataWidget();
          }

          final bookings = state.upcomingBookingModel!.data!.bookings!;

          return CustomScrollView(
            slivers: [
              // ── Top App Bar ──
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 24,
                    right: 24,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: MitablColors.surface.withValues(alpha: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (c) {
                                  return BlocProvider.value(
                                    value: context.read<BookingsCubit>(),
                                    child: const BookingFilterDialog(
                                        isUpComing: true),
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                borderRadius: MitablRadius.pillBorder,
                              ),
                              child: const Icon(
                                Icons.menu,
                                color: MitablColors.primary,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'miCook Vendor',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: MitablColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MitablColors.surfaceContainerLow,
                          border: Border.all(
                            color:
                                MitablColors.primary.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Page Header ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Bookings',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your scheduled orders for the day',
                        style: TextStyle(
                          fontSize: 16,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Filter Chips ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Bookings', 0),
                        const SizedBox(width: 12),
                        _buildFilterChip('Dine-in', 1),
                        const SizedBox(width: 12),
                        _buildFilterChip('Take-away', 2),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Booking Cards ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final booking = bookings[index];
                      final customer = booking.customer!;
                      final isDineIn = booking.orderTypeId == '1' ||
                          booking.orderTypeId == null;

                      // Filter logic
                      if (_selectedFilter == 1 && !isDineIn) {
                        return const SizedBox.shrink();
                      }
                      if (_selectedFilter == 2 && isDineIn) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildBookingCard(
                          context: context,
                          booking: booking,
                          customer: customer,
                          isDineIn: isDineIn,
                        ),
                      );
                    },
                    childCount: bookings.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int filterIndex) {
    final isSelected = _selectedFilter == filterIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? MitablColors.primary
              : MitablColors.secondaryContainer,
          borderRadius: MitablRadius.pillBorder,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MitablColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? MitablColors.onPrimary
                : MitablColors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required dynamic booking,
    required dynamic customer,
    required bool isDineIn,
  }) {
    final customerName = customer.name ?? 'Customer';
    final orderId = '#ORD-${booking.orderId ?? ''}';
    final timeLabel = '${booking.date ?? ''} ${booking.timeFrom ?? ''}';
    final items = booking.items ?? [];
    final totalAmount = 'AUD ${booking.itemTotalPrice ?? 0}';

    return Container(
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type badge + Order ID ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDineIn
                      ? const Color(0xFFD5E9BF)
                      : const Color(0xFFFFEDD5),
                  borderRadius: MitablRadius.pillBorder,
                ),
                child: Text(
                  isDineIn ? 'DINE-IN' : 'TAKE-AWAY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isDineIn
                        ? const Color(0xFF0B200A)
                        : const Color(0xFF431407),
                  ),
                ),
              ),
              Text(
                orderId,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Customer Name ──
          Text(
            customerName,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: MitablColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),

          // ── Schedule row ──
          Row(
            children: [
              const Icon(Icons.schedule, size: 16,
                  color: MitablColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Items container ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MitablColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ...items.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.food ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'x${item.quantity ?? 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Total
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: MitablColors.outlineVariant
                            .withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        totalAmount,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: MitablColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Mark In Progress button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                navigatorKey.currentState!.push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: context.read<BookingsCubit>(),
                      child: OrderDetailsBookings(
                        routeArguments: RouteArguments(
                          bookings: booking,
                          isUpcoming: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text(
                'Mark In Progress',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MitablColors.primary,
                foregroundColor: MitablColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: MitablRadius.pillBorder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
