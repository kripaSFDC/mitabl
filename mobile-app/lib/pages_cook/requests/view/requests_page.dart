import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/pages_cook/requests/cubit/requests_cubit.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

import '../../../helper/common_progress.dart';
import '../../../helper/no_data_widget.dart';
import '../../../helper/offline_error_widget.dart';
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
      body: BlocConsumer<RequestsCubit, RequestsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Stack(
            children: [
              state.requestBookingStatus!.isSubmissionInProgress
                  ? const Center()
                  : state.requestBookingStatus!.isSubmissionFailure &&
                          (state.requestBookingModel?.data?.bookings
                                  ?.isEmpty ??
                              true)
                      ? OfflineErrorWidget(
                          onRetry: context.read<RequestsCubit>().getRequests,
                        )
                      : state.requestBookingModel == null ||
                              state.requestBookingModel!.data!.bookings!
                                  .isEmpty
                          ? const NoDataWidget()
                          : CustomScrollView(
                              slivers: [
                                // ── Top App Bar ──
                                SliverToBoxAdapter(
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).padding.top +
                                          16,
                                      left: 24,
                                      right: 24,
                                      bottom: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MitablColors.surface
                                          .withValues(alpha: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Icon(
                                                Icons.arrow_back,
                                                color: MitablColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Text(
                                              'Mitabl',
                                              style: TextStyle(
                                                fontFamily: 'Nunito',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 20,
                                                color: MitablColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: MitablColors
                                                .surfaceContainerLow,
                                            border: Border.all(
                                              color: MitablColors
                                                  .primaryContainer
                                                  .withValues(alpha: 0.2),
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 20,
                                            color:
                                                MitablColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Header Section ──
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 24, 24, 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Order Requests',
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 32,
                                            color: MitablColors.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Review and manage your incoming culinary bookings.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color:
                                                MitablColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                    child: SizedBox(height: 32)),

                                // ── Request Cards List ──
                                SliverPadding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 0, 24, 120),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final booking = state
                                            .requestBookingModel!
                                            .data!
                                            .bookings![index];
                                        final customer = booking.customer!;
                                        final items = booking.items ?? [];
                                        final isDineIn =
                                            booking.orderTypeId == '1' ||
                                                booking.orderTypeId == null;

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 24),
                                          child: _buildRequestCard(
                                            context: context,
                                            booking: booking,
                                            customer: customer,
                                            items: items,
                                            isDineIn: isDineIn,
                                            index: index,
                                          ),
                                        );
                                      },
                                      childCount: state.requestBookingModel!
                                          .data!.bookings!.length,
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildRequestCard({
    required BuildContext context,
    required dynamic booking,
    required dynamic customer,
    required List<dynamic> items,
    required bool isDineIn,
    required int index,
  }) {
    final orderId = '#${booking.orderId ?? ''}';
    final customerName = customer.name ?? '';
    final timeLabel = '${booking.timeFrom ?? ''} - ${booking.timeTo ?? ''}';
    final totalAmount = 'AUD ${booking.itemTotalPrice ?? 0}';

    return Container(
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MitablColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Icon + Customer + Time ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDineIn
                      ? MitablColors.secondaryContainer
                      : const Color(0xFFFFEDD5),
                ),
                child: Icon(
                  isDineIn ? Icons.restaurant : Icons.local_mall,
                  color: isDineIn
                      ? MitablColors.onSecondaryContainer
                      : const Color(0xFF431407),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Time badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MitablColors.surfaceContainerLow,
                  borderRadius: MitablRadius.pillBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14,
                        color: MitablColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Items List ──
          ...items.take(3).map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.food ?? ''} x${item.quantity ?? 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '\$${item.price ?? 0}',
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
          const SizedBox(height: 8),

          // ── Total Amount ──
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: MitablColors.outlineVariant.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MitablColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  totalAmount,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: MitablColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Reject / Accept Buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final cubit = context.read<RequestsCubit>();
                    final reason = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => OrderRejectionSheet(
                        orderId: booking.orderId?.toString() ?? '',
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: Color(0xFF64748B),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: MitablRadius.pillBorder,
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<RequestsCubit>().onOrderAcceptDecline(
                          isAccept: true,
                          orderId: booking.orderId,
                          isFromOrderView: false,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MitablColors.primary,
                    foregroundColor: MitablColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: MitablColors.primary.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: MitablRadius.pillBorder,
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
