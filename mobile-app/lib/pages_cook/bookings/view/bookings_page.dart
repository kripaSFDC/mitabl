import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/pages_cook/bookings/cubit/bookings_cubit.dart';
import 'package:mitabl_user/pages_cook/bookings/elements/booking_filter_dialog.dart';
import 'package:mitabl_user/pages_cook/bookings/elements/order_details_booking.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';

class Bookings extends StatefulWidget {
  const Bookings({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) =>
            BookingsCubit(BookingRepository(context.read<UserRepository>())),
        child: const Bookings(),
      ),
    );
  }

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  int _selectedFilter = 0; // 0=All, 1=Completed, 2=Cancelled, 3=Refunded

  @override
  void initState() {
    super.initState();
    context.read<BookingsCubit>().onStatusChanged(data: '');
    context.read<BookingsCubit>().onSortByChanged(data: '');
    context.read<BookingsCubit>().getBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: BlocConsumer<BookingsCubit, BookingsState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state.bookingStatus!.isSubmissionInProgress) {
            return const Center(child: CommonProgressWidget());
          }
          if (state.bookingModel == null ||
              state.bookingModel!.data!.bookings!.isEmpty) {
            return const NoDataWidget();
          }

          final bookings = state.bookingModel!.data!.bookings!;

          // Compute monthly performance
          double monthlyEarnings = 0;
          int completedCount = 0;
          for (final b in bookings) {
            if (b.status == 1) {
              final price = b.itemTotalPrice;
              if (price is num) {
                monthlyEarnings += price.toDouble();
              } else if (price is String) {
                monthlyEarnings += double.tryParse(price) ?? 0;
              }
              completedCount++;
            }
          }

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
                                        isUpComing: false),
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
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
                              fontWeight: FontWeight.w900,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'History',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                          color: MitablColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Review your completed and archived culinary journeys.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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
                        _buildFilterChip('Completed', 1),
                        const SizedBox(width: 12),
                        _buildFilterChip('Cancelled', 2),
                        const SizedBox(width: 12),
                        _buildFilterChip('Refunded', 3),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Monthly Performance Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: MitablColors.primary,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          size: 36,
                          color: MitablColors.onPrimary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Monthly Performance',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: MitablColors.onPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You served $completedCount orders this month.',
                          style: TextStyle(
                            fontSize: 14,
                            color: MitablColors.onPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'AUD ${monthlyEarnings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 36,
                            color: MitablColors.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GROSS REVENUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: MitablColors.onPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── History Cards ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final booking = bookings[index];
                      final customer = booking.customer;
                      final statusCode = booking.status ?? -1;

                      // Filter logic
                      if (_selectedFilter == 1 && statusCode != 1) {
                        return const SizedBox.shrink();
                      }
                      if (_selectedFilter == 2 && statusCode != 0) {
                        return const SizedBox.shrink();
                      }
                      if (_selectedFilter == 3 && statusCode != 2) {
                        return const SizedBox.shrink();
                      }

                      String statusLabel;
                      Color statusBgColor;
                      Color statusTextColor;
                      switch (statusCode) {
                        case 0:
                          statusLabel = 'Cancelled';
                          statusBgColor = const Color(0xFFF1F5F9);
                          statusTextColor = MitablColors.onSurfaceVariant;
                          break;
                        case 1:
                          statusLabel = 'Completed';
                          statusBgColor = MitablColors.secondaryContainer;
                          statusTextColor = MitablColors.onSecondaryContainer;
                          break;
                        case 2:
                          statusLabel = 'Pending';
                          statusBgColor = const Color(0xFFF8FAFC);
                          statusTextColor = MitablColors.onSurfaceVariant;
                          break;
                        default:
                          statusLabel = 'Accepted';
                          statusBgColor = MitablColors.secondaryContainer;
                          statusTextColor = MitablColors.onSecondaryContainer;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildHistoryCard(
                          context: context,
                          booking: booking,
                          customer: customer,
                          statusLabel: statusLabel,
                          statusBgColor: statusBgColor,
                          statusTextColor: statusTextColor,
                          statusCode: statusCode,
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
              : MitablColors.surfaceContainerLow,
          borderRadius: MitablRadius.pillBorder,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MitablColors.primary.withValues(alpha: 0.1),
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
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? MitablColors.onPrimary
                : MitablColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required BuildContext context,
    required dynamic booking,
    required dynamic customer,
    required String statusLabel,
    required Color statusBgColor,
    required Color statusTextColor,
    required int statusCode,
  }) {
    final customerName = customer?.name ?? 'Customer';
    final orderId = '#MC-${booking.orderId ?? ''}';
    final date = booking.date ?? '';
    final totalAmount = 'AUD ${booking.itemTotalPrice ?? 0}';
    final isCancelled = statusCode == 0;

    return GestureDetector(
      onTap: () {
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<BookingsCubit>(),
              child: OrderDetailsBookings(
                routeArguments: RouteArguments(
                  bookings: booking,
                  isUpcoming: false,
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isCancelled
              ? MitablColors.surfaceContainerLow
              : MitablColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isCancelled
              ? null
              : [
                  BoxShadow(
                    color: MitablColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 24),
                  ),
                ],
          border: isCancelled
              ? Border.all(
                  color: MitablColors.outlineVariant.withValues(alpha: 0.05))
              : Border.all(
                  color: MitablColors.outlineVariant.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Icon + Order info + Status badge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circle avatar with icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MitablColors.secondaryContainer,
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: MitablColors.onSecondaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order $orderId',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: MitablColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: MitablRadius.pillBorder,
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Info row ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color:
                          MitablColors.outlineVariant.withValues(alpha: 0.1)),
                  bottom: BorderSide(
                      color:
                          MitablColors.outlineVariant.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer',
                          style: TextStyle(
                            fontSize: 12,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalAmount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Rating row (for completed) ──
            if (statusCode == 1 && customer?.rating != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        Icons.star,
                        size: 16,
                        color: i < (customer.rating?.round() ?? 0)
                            ? MitablColors.primary
                            : MitablColors.outlineVariant,
                      );
                    }),
                  ],
                ),
              ),

            // ── Action buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    navigatorKey.currentState!.push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: context.read<BookingsCubit>(),
                          child: OrderDetailsBookings(
                            routeArguments: RouteArguments(
                              bookings: booking,
                              isUpcoming: false,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF506140),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
