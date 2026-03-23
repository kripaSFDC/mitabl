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
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
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
      appBar: GlassAppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: MitablColors.onSurface),
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) {
                  return BlocProvider.value(
                    value: context.read<BookingsCubit>(),
                    child: const BookingFilterDialog(isUpComing: false),
                  );
                },
              );
            },
          ),
        ],
      ),
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

          return ListView(
            padding: const EdgeInsets.all(MitablSpacing.pagePadding),
            children: [
              // Monthly Performance card
              MitablCard(
                color: MitablColors.primaryContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Performance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: MitablColors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'AUD ${monthlyEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onPrimary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount completed orders',
                            style: TextStyle(
                              fontSize: 13,
                              color: MitablColors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.trending_up,
                      size: 48,
                      color: MitablColors.onPrimary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MitablSpacing.listItem),

              // History cards
              ...List.generate(bookings.length, (index) {
                final booking = bookings[index];
                final customer = booking.customer;
                final statusCode = booking.status ?? -1;

                String statusLabel;
                Color statusBgColor;
                Color statusTextColor;
                switch (statusCode) {
                  case 0:
                    statusLabel = 'Cancelled';
                    statusBgColor = MitablColors.error;
                    statusTextColor = MitablColors.onPrimary;
                    break;
                  case 1:
                    statusLabel = 'Completed';
                    statusBgColor = MitablColors.accent;
                    statusTextColor = MitablColors.onPrimary;
                    break;
                  case 2:
                    statusLabel = 'Pending';
                    statusBgColor = MitablColors.tertiaryFixedDim;
                    statusTextColor = MitablColors.onSurface;
                    break;
                  default:
                    statusLabel = 'Accepted';
                    statusBgColor = MitablColors.secondaryContainer;
                    statusTextColor = MitablColors.onSecondaryContainer;
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < bookings.length - 1
                        ? MitablSpacing.listItem
                        : 0,
                  ),
                  child: MitablCard(
                    useGhostBorder: true,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer + date row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: MitablColors.surfaceContainerLow,
                              child: Text(
                                (customer?.name ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer?.name ?? 'Customer',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.date ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Amount
                            Text(
                              'AUD ${booking.itemTotalPrice ?? 0}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Rating + status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (customer?.rating != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Color(0xffFFA200),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    customer!.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: MitablRadius.pillBorder,
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
