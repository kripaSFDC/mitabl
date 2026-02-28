<?php

namespace App\Services;

use App\Mail\RefundInvoice;
use App\Models\CancelReason;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Refund;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use RuntimeException;

class AdminPaymentRefundService
{
    public function __construct(
        private readonly PaymentService $paymentService,
        private readonly AdminAuditLogService $auditLogService,
    ) {
    }

    public function refundFull(Payment $payment, string $reason, int $actorAdminId): array
    {
        $reason = trim($reason);
        if ($reason === '') {
            throw new RuntimeException('Refund reason is required.');
        }

        try {
            $result = DB::transaction(function () use ($payment, $reason, $actorAdminId): array {
                $payment = Payment::query()->lockForUpdate()->find($payment->id);
                if (! $payment) {
                    throw new RuntimeException('Payment record not found.');
                }

                $order = Order::query()->with(['payment', 'user'])->lockForUpdate()->find($payment->order_id);
                if (! $order) {
                    throw new RuntimeException('Order linked to this payment was not found.');
                }

                if (! $order->payment || ! $order->payment->payment_id) {
                    throw new RuntimeException('Payment intent is missing for this order.');
                }

                if (! (bool) $payment->confirm && ! (bool) $order->paid) {
                    throw new RuntimeException('Only confirmed/paid payments can be refunded.');
                }

                $existingRefund = Refund::query()->where('order_id', $order->id)->first();
                if ($existingRefund || (int) $order->refund_percentage >= 100) {
                    return [
                        'status' => 'already_refunded',
                        'order_id' => $order->id,
                        'payment_id' => $payment->id,
                        'refund_id' => $existingRefund?->id,
                        'amount' => (float) $order->total_price,
                    ];
                }

                $refundResponse = $this->paymentService->refundAmount(
                    (string) $order->payment->payment_id,
                    (float) $order->total_price,
                    0,
                    'admin_full_refund_order_' . $order->id
                );

                $refund = Refund::create([
                    'order_id' => $order->id,
                    'user_id' => $order->user_id,
                    'percentage' => 100,
                    'amount' => (float) $order->total_price,
                    'balance_trans' => $refundResponse->balance_transaction ?? null,
                    'refund_date' => Carbon::now(),
                    'reciept_no' => Carbon::now(),
                    'status' => 1,
                ]);

                $order->refund_percentage = 100;
                $order->save();

                CancelReason::updateOrCreate(
                    ['order_id' => $order->id, 'subject' => 'Admin full refund'],
                    [
                        'ref_id' => $actorAdminId,
                        'comment' => $reason,
                        'by_user' => 'admin',
                    ]
                );

                if ($order->user?->email) {
                    Mail::to($order->user->email)->queue((new RefundInvoice($order->user, $order, 1, 100))->afterCommit());
                }

                return [
                    'status' => 'refunded',
                    'order_id' => $order->id,
                    'payment_id' => $payment->id,
                    'refund_id' => $refund->id,
                    'amount' => (float) $order->total_price,
                ];
            });
        } catch (\Throwable $throwable) {
            $this->auditLogService->log('payments.refund_full', request(), [
                'payment_id' => $payment->id,
                'reason' => $reason,
                'result' => 'failed',
                'error' => $throwable->getMessage(),
            ]);

            throw $throwable;
        }

        $this->auditLogService->log('payments.refund_full', request(), [
            'order_id' => $result['order_id'] ?? null,
            'payment_id' => $result['payment_id'] ?? null,
            'refund_id' => $result['refund_id'] ?? null,
            'amount' => $result['amount'] ?? null,
            'reason' => $reason,
            'result' => $result['status'] ?? 'unknown',
        ]);

        return $result;
    }
}
