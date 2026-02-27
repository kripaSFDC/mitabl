<?php
namespace App\Http\Controllers\Api;

use App\Models\Mikitchn;
use App\Models\User;
use App\Models\Review;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Validator;
use Storage;
use Carbon\Carbon;
use App\Http\Resources\Restaurant\Review as ReviewResource;
use App\Http\Resources\Reviews\Reviews as ReviewsResource;

class ReviewController extends Controller
{
    public $data=[];

    public function addReviewToRestaurant(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'review' => 'required|string',
            'restaurant_id' => 'required|integer',
            'order_id' => 'required|integer|unique:reviews,order_id',
            'review_tag' => 'required|string',
            'rating' => 'required|numeric|min:0|max:5',
        ]);

        if($validator->fails()){
            return $this->responser($this->data,$validator->errors()->first());
        }
        // die('gnbgnf');
        $review = new Review;
        $review->review = $request->review;
        $review->review_tag = $request->review_tag;
        $review->rating = $request->rating;
        $review->user_id = auth()->user()->id;
        $review->mikitchn_id = $request->restaurant_id;
        $review->order_id = $request->order_id;
        $review->by_user = 'customer';
        $review->save();
        // auth()->user()->restaurant->reviews()->save($review);
        $rvw = new ReviewsResource($review);
        return $this->responser($rvw, 'Review Added Successfully.');
    }

    public function reviewOfRestaurant(Request $request)
    {
        $queryparams = $request->query();
        $review = Review::where('mikitchn_id', auth()->user()->restaurant->id)->where('by_user','customer')->orderBy('id', 'desc');
        $this->data['total_count'] = $review->count();
        // $reviews = auth()->user()->restaurant->reviews();
        // print_r($review); die();
        $data = $review->paginate($queryparams['limit']);
        $this->data['reviews'] = ReviewsResource::collection($data);

        return $this->responser($this->data, 'Kitchen Reviews');

    }

    public function getKitchenReviews(Request $request,$id)
    {
        $queryparams = $request->query();
        // $review = Review::where('user_id', auth()->user()->id)->where('by_user','kitchen')->orderBy('id', 'desc');
        $review = Review::where('mikitchn_id', $id)->where('by_user','customer')->orderBy('id', 'desc');
        $this->data['total_count'] = $review->count();
        // $reviews = auth()->user()->restaurant->reviews();
        // print_r($review); die();
        $data = $review->paginate($queryparams['limit']);
        $this->data['reviews'] = ReviewsResource::collection($data);

        return $this->responser($this->data, 'Kitchen Reviews');

    }

    public function addReviewToFoodie(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'review' => 'required|string',
            'user_id' => 'required|integer',
            'review_tag' => 'required|string',
            'rating' => 'required|numeric|min:0|max:5',
        ]);

        if($validator->fails()){
            return $this->responser($this->data,$validator->errors()->first());
        }
        // die('gnbgnf');
        $review = new Review;
        $review->review = $request->review;
        $review->review_tag = $request->review_tag;
        $review->rating = $request->rating;
        $review->user_id = $request->user_id;
        $review->mikitchn_id = auth()->user()->restaurant->id;
        $review->by_user = 'kitchen';
        $review->save();
        // auth()->user()->restaurant->reviews()->save($review);
        $rvw = new ReviewsResource($review);
        return $this->responser($rvw, 'Review Added Successfully.');
    }

    public function reviewOfFoodie(Request $request){

        $review = Review::where('user_id', auth()->user()->id)->where('by_user','kitchen')->orderBy('id', 'desc')->get();
        // $reviews = auth()->user()->restaurant->reviews();
        // print_r($review); die();
        $data = ReviewResource::collection($review);

        return $this->responser($data, 'Foodie Reviews');

    }

    public function show()
    {
        $restaurant = Auth::user()->restaurant;
        if ($restaurant) {
            $review = Review::where('restaurant_id', $restaurant->id)->orderBy('restaurant_id', 'asc')->paginate(15);
            return view('restaurant.reviews.show', ['reviews' => $review, 'restaurants' => $restaurant]);
        } else {
            $restaurant = Restaurant::all();
            $review = Review::orderBy('restaurant_id', 'asc')->paginate(15);
            return view('restaurant.reviews.show', ['reviews' => $review, 'restaurants' => $restaurant]);
        }
    }

    public function search(Request $r)
    {
        $id = $r->restaurant_id;

        $review = Review::orderBy('id', 'asc')->where('restaurant_id', $id)->paginate(15);

        $restaurant = Restaurant::all();

        return view('restaurant.reviews.show')->with('restaurants', $restaurant)->with('reviews', $review);

    }

    public function destroy($id){
        $review = Review::where('id', $id)->first();
        $review->delete();

        Session::flash('success', 'Review deleted successfully');
        return redirect()->route('reviews.show');
    }
}
