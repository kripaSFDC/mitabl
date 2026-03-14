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
            'status' => ['nullable', 'string'],
            'from_date' => ['nullable', 'date_format:Y-m-d'],
            'to_date' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from_date'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $limit = (int) ($request->query('limit', 10));
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
            $statusFilters = collect(explode(',', (string) $request->query('status')))
                ->map(fn ($status) => trim((string) $status))
                ->filter(fn ($status) => $status !== '' && is_numeric($status))
                ->map(fn ($status) => (int) $status)
                ->values();

            if ($statusFilters->isNotEmpty()) {
                $query->whereIn('status', $statusFilters->all());
            }
        }

        if ($request->filled('from_date')) {
            $query->whereDate('delivery_date', '>=', (string) $request->query('from_date'));
        }

        if ($request->filled('to_date')) {
            $query->whereDate('delivery_date', '<=', (string) $request->query('to_date'));
        }

        $paginator = $query->orderByDesc('id')->paginate($limit);

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
        $user = Auth::user();

        $paginator = $user->getFavoriteItems(Mikitchn::class)
            ->with(['addedimage:id,ref_id,model_name,path', 'certificate:id,mikitchn_id,abn,abn_gst,status'])
            ->withAvg('reviews', 'rating')
            ->orderByDesc('id')
            ->paginate($limit);

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
            'restaurant_id' => ['required', 'integer', 'exists:mikitchns,id'],
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
            'status' => ['nullable', 'string'],
            'from_date' => ['nullable', 'date_format:Y-m-d'],
            'to_date' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from_date'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $limit = (int) ($request->query('limit', 10));

        $query = Payment::query()
            ->with('order')
            ->whereHas('order', function ($orderQuery): void {
                $orderQuery->where('user_id', (int) Auth::id());
            });

        if ($request->filled('status')) {
            $query->where('status', (string) $request->query('status'));
        }

        if ($request->filled('from_date')) {
            $query->whereDate('created_at', '>=', (string) $request->query('from_date'));
        }

        if ($request->filled('to_date')) {
            $query->whereDate('created_at', '<=', (string) $request->query('to_date'));
        }

        $paginator = $query->orderByDesc('id')->paginate($limit);

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
