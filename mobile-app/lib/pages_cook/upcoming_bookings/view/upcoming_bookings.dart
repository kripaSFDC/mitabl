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
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';

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
      appBar: GlassAppBar(
        title: const Text('Upcoming Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: MitablColors.onSurface),
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) {
                  return BlocProvider.value(
                    value: context.read<BookingsCubit>(),
                    child: const BookingFilterDialog(isUpComing: true),
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
          if (state.upcomingBookingStatus!.isSubmissionInProgress) {
            return const Center(child: CommonProgressWidget());
          }
          if (state.upcomingBookingModel == null ||
              state.upcomingBookingModel!.data!.bookings!.isEmpty) {
            return const NoDataWidget();
          }

          final bookings = state.upcomingBookingModel!.data!.bookings!;

          return ListView.separated(
            padding: const EdgeInsets.all(MitablSpacing.pagePadding),
            itemCount: bookings.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: MitablSpacing.listItem),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final customer = booking.customer!;
              final isInProgress = booking.status == 5;

              return MitablCard(
                useGhostBorder: true,
                onTap: () {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: MitablColors.surfaceContainerLow,
                          child: Text(
                            (customer.name ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
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
                                customer.name ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: MitablColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${booking.date ?? ''} | ${booking.timeFrom ?? ''} - ${booking.timeTo ?? ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Items + amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${booking.items?.length ?? 0} item${(booking.items?.length ?? 0) == 1 ? '' : 's'} | ${booking.persons ?? 0} person${(booking.persons ?? 0) == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
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

                    // Status chip + View Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MitablChip(
                          label: isInProgress ? 'In Progress' : 'Confirmed',
                          selected: true,
                        ),
                        const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MitablColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
