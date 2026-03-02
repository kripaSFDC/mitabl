<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Stripe\Event;
use Stripe\Exception\SignatureVerificationException;
use Stripe\Webhook;
use UnexpectedValueException;

class StripeWebhookController extends Controller
{
    public function handle(Request $request): JsonResponse
    {
        $signingSecret = trim((string) config('stripe.webhook_signing_secret', ''));
        if ($signingSecret === '') {
            return response()->json([
                'status' => 'ignored',
                'message' => 'Stripe webhook signing secret is not configured.',
            ], 503);
        }

        $payload = $request->getContent();
        $signature = (string) $request->header('Stripe-Signature', '');

        try {
            $event = Webhook::constructEvent($payload, $signature, $signingSecret);
        } catch (UnexpectedValueException|SignatureVerificationException $exception) {
            return response()->json([
                'status' => 'invalid',
                'message' => $exception->getMessage(),
            ], 400);
        }

        $this->handleEvent($event);

        return response()->json(['status' => 'ok']);
    }

    private function handleEvent(Event $event): void
    {
        $object = $event->data->object;

        switch ($event->type) {
            case 'payment_intent.succeeded':
                $this->markPaymentIntentStatus((string) ($object->id ?? ''), 'succeeded');
                break;

            case 'payment_intent.payment_failed':
                $this->markPaymentIntentStatus((string) ($object->id ?? ''), 'failed');
                break;

            case 'payment_intent.canceled':
                $this->markPaymentIntentStatus((string) ($object->id ?? ''), 'canceled');
                break;

            case 'charge.refunded':
                $intentId = (string) ($object->payment_intent ?? '');
                if ($intentId !== '') {
                    $this->markPaymentIntentStatus($intentId, 'refunded');
                }
                break;
        }
    }

    private function markPaymentIntentStatus(string $intentId, string $status): void
    {
        if ($intentId === '') {
            return;
        }

        $payment = Payment::query()->where('payment_id', $intentId)->first();
        if (! $payment) {
            return;
        }

        $payment->status = $status;

        if (in_array($status, ['succeeded', 'refunded'], true)) {
            $payment->confirm = true;
            $payment->confirm_date_time = $payment->confirm_date_time ?? Carbon::now();
        }

        if (in_array($status, ['failed', 'canceled'], true)) {
            $payment->confirm = false;
        }

        $payment->save();

        $order = Order::query()->find($payment->order_id);
        if (! $order) {
            return;
        }

        if ($status === 'succeeded') {
            $order->paid = 1;
        }

        if ($status === 'failed' || $status === 'canceled') {
            $order->paid = 0;
        }

        $order->save();
    }
}
