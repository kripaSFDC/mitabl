import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages_cook/requests/cubit/requests_cubit.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

import '../../../helper/common_progress.dart';
import '../../../helper/no_data_widget.dart';
import '../../../helper/offline_error_widget.dart';
import '../elements/order_details_view.dart';
import '../elements/order_rejection_sheet.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  @override
  void initState() {
    super.initState();
    context.read<RequestsCubit>().getRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(title: const Text('Order Requests')),
      body: BlocConsumer<RequestsCubit, RequestsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Stack(
            children: [
              state.requestBookingStatus!.isSubmissionInProgress
                  ? const Center()
                  : state.requestBookingStatus!.isSubmissionFailure &&
                        (state.requestBookingModel?.data?.bookings?.isEmpty ??
                            true)
                  ? OfflineErrorWidget(
                      onRetry: context.read<RequestsCubit>().getRequests,
                    )
                  : state.requestBookingModel == null ||
                        state.requestBookingModel!.data!.bookings!.isEmpty
                  ? const NoDataWidget()
                  : ListView.separated(
                      padding: const EdgeInsets.all(MitablSpacing.pagePadding),
                      itemCount:
                          state.requestBookingModel!.data!.bookings!.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: MitablSpacing.listItem),
                      itemBuilder: (context, index) {
                        final booking = state
                            .requestBookingModel!
                            .data!
                            .bookings![index];
                        final customer = booking.customer!;
                        final itemCount = booking.items?.length ?? 0;

                        return MitablCard(
                          useGhostBorder: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer info row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        MitablColors.surfaceContainerLow,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            navigatorKey.currentState!
                                                .pushNamed(
                                                  '/UserDetails',
                                                  arguments: RouteArguments(
                                                    customer: customer,
                                                  ),
                                                );
                                          },
                                          child: Text(
                                            customer.name ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: MitablColors.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${booking.date ?? ''} | ${booking.timeFrom ?? ''} - ${booking.timeTo ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color:
                                                MitablColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Items preview
                              Text(
                                '$itemCount item${itemCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Total amount
                              Text(
                                'AUD ${booking.itemTotalPrice ?? 0}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurface,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              const SizedBox(height: 8),

                              // View Details
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () {
                                    navigatorKey.currentState!.push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => BlocProvider.value(
                                          value:
                                              context.read<RequestsCubit>(),
                                          child: OrderDetails(
                                            routeArguments: RouteArguments(
                                              bookings: booking,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View Details',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: MitablColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Accept / Decline buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: MitablButton(
                                      label: 'Decline',
                                      variant: MitablButtonVariant.outline,
                                      onPressed: () async {
                                        final cubit =
                                            context.read<RequestsCubit>();
                                        final reason =
                                            await showModalBottomSheet<String>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) => OrderRejectionSheet(
                                            orderId:
                                                booking.orderId?.toString() ??
                                                    '',
                                          ),
                                        );
                                        if (reason != null) {
                                          cubit.onOrderAcceptDecline(
                                            isAccept: false,
                                            orderId: booking.orderId,
                                            isFromOrderView: false,
                                            cancelComment: reason,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: MitablButton(
                                      label: 'Accept',
                                      variant: MitablButtonVariant.primary,
                                      onPressed: () {
                                        context
                                            .read<RequestsCubit>()
                                            .onOrderAcceptDecline(
                                              isAccept: true,
                                              orderId: booking.orderId,
                                              isFromOrderView: false,
                                            );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              state.requestBookingStatus!.isSubmissionInProgress
                  ? const CommonProgressWidget()
                  : const SizedBox(),
            ],
          );
        },
      ),
    );
  }
}
