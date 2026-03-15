<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Http\Resources\Order\Order as OrderResource;
use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class AccountFoodieController extends Controller
{
    public function orders(Request $request)
    {
        $validator = Validator::make($request->query(), [
            'page' => ['nullable', 'integer', 'min:1'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
            'status' => ['nullable', 'regex:/^\d+(,\d+)*$/'],
            'from_date' => ['nullable', 'date_format:Y-m-d'],
            'to_date' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from_date'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $limit = (int) ($request->query('limit', 10));
        $page = (int) ($request->query('page', 1));

        $query = Order::query()
            ->withCasts([
                'delivery_date' => 'date',
                'delivery_time_from' => 'datetime:H:i:s',
                'delivery_time_to' => 'datetime:H:i:s',
            ])
            ->with([
                'orderdata.food',
                'Mikitchn.addedimage',
                'user',
                'promocode',
                'cancelreason.actor.restaurant',
                'review',
                'payment',
            ])
            ->where('user_id', (int) Auth::id());

        if ($request->filled('status')) {
            $statuses = $this->parseIntegerStatusFilter((string) $request->query('status'));
            if (! $this->containsOnlyAllowedOrderStatuses($statuses)) {
                return $this->responser([], 'status filter contains unsupported order status values.', 422);
            }

            $query->whereIn('status', $statuses);
        }

        if ($request->filled('from_date')) {
            $query->whereDate('delivery_date', '>=', (string) $request->query('from_date'));
        }

        if ($request->filled('to_date')) {
            $query->whereDate('delivery_date', '<=', (string) $request->query('to_date'));
        }

        $paginator = $query->orderByDesc('id')->paginate($limit, ['*'], 'page', $page);

        return $this->responser([
            'total_count' => $paginator->total(),
            'items' => OrderResource::collection($paginator->getCollection()),
            'pagination' => $this->paginationMeta($paginator),
        ], 'customer order history.');
    }

    public function favorites(Request $request)
    {
        $validator = Validator::make($request->query(), [
            'page' => ['nullable', 'integer', 'min:1'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $limit = (int) ($request->query('limit', 10));
        $page = (int) ($request->query('page', 1));
        $user = Auth::user();

        $paginator = $user->getFavoriteItems(Mikitchn::class)
            ->with(['addedimage:id,ref_id,model_name,path', 'certificate:id,mikitchn_id,abn,abn_gst,status'])
            ->withAvg('reviews', 'rating')
            ->orderByDesc('id')
            ->paginate($limit, ['*'], 'page', $page);

        $paginator->getCollection()->each(function (Mikitchn $kitchen): void {
            $kitchen->setAttribute('is_favourited', true);
        });

        return $this->responser([
            'total_count' => $paginator->total(),
            'items' => RestaurantResource::collection($paginator->getCollection()),
            'pagination' => $this->paginationMeta($paginator),
        ], 'customer favorites.');
    }

    public function toggleFavorite(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'restaurant_id' => ['required', 'integer', 'min:1'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $user = Auth::user();
        $kitchen = Mikitchn::query()->find((int) $request->input('restaurant_id'));

        if (! $kitchen) {
            return $this->responser([], 'Restaurant not found.', 404);
        }

        $user->toggleFavorite($kitchen);

        return $this->responser([
            'favorite' => (int) $user->hasFavorited($kitchen),
        ], 'favorite updated.');
    }

    public function paymentHistory(Request $request)
    {
        $validator = Validator::make($request->query(), [
            'page' => ['nullable', 'integer', 'min:1'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
            'status' => ['nullable', 'regex:/^[A-Za-z0-9_\-]+(,[A-Za-z0-9_\-]+)*$/'],
            'from_date' => ['nullable', 'date_format:Y-m-d'],
            'to_date' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from_date'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $limit = (int) ($request->query('limit', 10));
        $page = (int) ($request->query('page', 1));

        $query = Payment::query()
            ->whereHas('order', function ($orderQuery): void {
                $orderQuery->where('user_id', (int) Auth::id());
            });

        if ($request->filled('status')) {
            $query->whereIn('status', $this->parseStringStatusFilter((string) $request->query('status')));
        }

        if ($request->filled('from_date')) {
            $query->whereDate('created_at', '>=', (string) $request->query('from_date'));
        }

        if ($request->filled('to_date')) {
            $query->whereDate('created_at', '<=', (string) $request->query('to_date'));
        }

        $paginator = $query->orderByDesc('id')->paginate($limit, ['*'], 'page', $page);

        $items = $paginator->getCollection()->map(function (Payment $payment): array {
            return [
                'id' => $payment->id,
                'order_id' => $payment->order_id,
                'payment_id' => $payment->payment_id,
                'card_id' => $payment->card_id,
                'amount' => (float) $payment->amount,
                'status' => $payment->status,
                'confirm' => (bool) $payment->confirm,
                'confirmed_at' => optional($payment->confirm_date_time)->toISOString(),
                'created_at' => optional($payment->created_at)->toISOString(),
            ];
        })->values();

        return $this->responser([
            'total_count' => $paginator->total(),
            'items' => $items,
            'pagination' => $this->paginationMeta($paginator),
        ], 'customer payment history.');
    }

    private function parseIntegerStatusFilter(string $statusFilter): array
    {
        return collect(explode(',', $statusFilter))
            ->map(fn (string $status) => (int) trim($status))
            ->unique()
            ->values()
            ->all();
    }

    private function parseStringStatusFilter(string $statusFilter): array
    {
        return collect(explode(',', $statusFilter))
            ->map(fn (string $status) => trim($status))
            ->filter(fn (string $status) => $status !== '')
            ->unique()
            ->values()
            ->all();
    }


    private function containsOnlyAllowedOrderStatuses(array $statuses): bool
    {
        $allowedStatuses = [
            Order::STATUS_LEGACY_CANCELLED,
            Order::STATUS_COMPLETED,
            Order::STATUS_REQUESTED,
            Order::STATUS_CONFIRMED,
            Order::STATUS_CANCELLED,
            Order::STATUS_IN_PROGRESS,
        ];

        foreach ($statuses as $status) {
            if (! in_array($status, $allowedStatuses, true)) {
                return false;
            }
        }

        return true;
    }

    private function paginationMeta(LengthAwarePaginator $paginator): array
    {
        return [
            'page' => $paginator->currentPage(),
            'limit' => $paginator->perPage(),
            'total_pages' => $paginator->lastPage(),
            'has_more' => $paginator->hasMorePages(),
        ];
    }
}
