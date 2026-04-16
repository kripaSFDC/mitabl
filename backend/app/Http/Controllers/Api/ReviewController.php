<?php
namespace App\Http\Controllers\Api;

use App\Models\Review;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Validator;
use App\Http\Resources\Reviews\Reviews as ReviewsResource;
use Illuminate\Validation\Rule;

class ReviewController extends Controller
{

    public function addReviewToRestaurant(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'review' => 'required|string',
            'restaurant_id' => 'required|integer|exists:mikitchns,id',
            'order_id' => [
                'required',
                'integer',
                Rule::unique('reviews', 'order_id')->where(fn ($query) => $query->where('by_user', 'customer')),
            ],
            'review_tag' => 'required|string',
            'rating' => 'required|numeric|min:0|max:5',
            'photos' => 'nullable|array|max:5',
            'photos.*' => 'image|mimes:jpeg,png,jpg|max:10240',
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
        }
        $order = Order::query()->find((int) $request->order_id);
        if (! $order) {
            return $this->responser([], 'Order not found.', 404);
        }
        if ((int) $order->user_id !== (int) auth()->id()) {
            return $this->responser([], 'You are not authorized for this order.', 403);
        }
        if ((int) $order->mikitchn_id !== (int) $request->restaurant_id) {
            return $this->responser([], 'Order does not belong to the selected restaurant.', 422);
        }
        if ((int) $order->status !== Order::STATUS_COMPLETED) {
            return $this->responser([], 'Reviews are allowed only for completed orders.', 422);
        }

        $review = new Review;
        $review->review = $request->review;
        $review->review_tag = $request->review_tag;
        $review->rating = $request->rating;
        $review->user_id = auth()->user()->id;
        $review->mikitchn_id = $request->restaurant_id;
        $review->order_id = $request->order_id;
        $review->by_user = 'customer';
        $review->save();

        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $photo) {
                $path = $photo->store('reviews', 'public');
                \App\Models\Image::create([
                    'ref_id' => $review->id,
                    'model_name' => 'review',
                    'path' => $path,
                ]);
            }
        }

        $rvw = new ReviewsResource($review);
        return $this->responser($rvw, 'Review Added Successfully.');
    }

    public function reviewOfRestaurant(Request $request)
    {
        $queryparams = $request->query();
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);
        $review = Review::where('mikitchn_id', auth()->user()->restaurant->id)->where('by_user','customer')->orderBy('id', 'desc');
        $data = [
            'total_count' => $review->count(),
            'reviews' => ReviewsResource::collection($review->paginate($limit)),
        ];

        return $this->responser($data, 'Kitchen Reviews');

    }

    public function getKitchenReviews(Request $request,$id)
    {
        $queryparams = $request->query();
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);
        $review = Review::where('mikitchn_id', $id)->where('by_user','customer')->orderBy('id', 'desc');
        $data = [
            'total_count' => $review->count(),
            'reviews' => ReviewsResource::collection($review->paginate($limit)),
        ];

        return $this->responser($data, 'Kitchen Reviews');

    }

    public function addReviewToFoodie(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'review' => 'required|string',
            'user_id' => 'required|integer|exists:users,id',
            'order_id' => [
                'required',
                'integer',
                Rule::unique('reviews', 'order_id')->where(fn ($query) => $query->where('by_user', 'kitchen')),
            ],
            'review_tag' => 'required|string',
            'rating' => 'required|numeric|min:0|max:5',
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
        }
        $restaurant = auth()->user()->restaurant;
        if (! $restaurant) {
            return $this->responser([], 'Restaurant profile not found.', 404);
        }

        $targetUser = User::query()->find((int) $request->user_id);
        if (! $targetUser || (int) $targetUser->role_id !== 3) {
            return $this->responser([], 'Target user must be a foodie account.', 422);
        }

        $order = Order::query()->find((int) $request->order_id);
        if (! $order) {
            return $this->responser([], 'Order not found.', 404);
        }
        if ((int) $order->mikitchn_id !== (int) $restaurant->id || (int) $order->user_id !== (int) $targetUser->id) {
            return $this->responser([], 'Order is not linked to this restaurant and foodie.', 422);
        }
        if ((int) $order->status !== Order::STATUS_COMPLETED) {
            return $this->responser([], 'Reviews are allowed only for completed orders.', 422);
        }

        $review = new Review;
        $review->review = $request->review;
        $review->review_tag = $request->review_tag;
        $review->rating = $request->rating;
        $review->user_id = $request->user_id;
        $review->mikitchn_id = $restaurant->id;
        $review->order_id = (int) $request->order_id;
        $review->by_user = 'kitchen';
        $review->save();
        $rvw = new ReviewsResource($review);
        return $this->responser($rvw, 'Review Added Successfully.');
    }

}

