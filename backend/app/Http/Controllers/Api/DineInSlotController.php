<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Restaurant\DineInSlot as DineInSlotResource;
use App\Models\DineInSlot;
use App\Services\DineInSlotService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use InvalidArgumentException;

class DineInSlotController extends Controller
{
    public function __construct(private DineInSlotService $dineInSlotService)
    {
    }

    public function index(Request $request)
    {
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        if (! Schema::hasTable('dine_in_slots')) {
            return $this->responser([], 'Dine-in slots are not yet available.', 422);
        }

        $slots = $kitchen->dineInSlots()->orderBy('day_of_week')->orderBy('start_time')->get();

        return $this->responser(DineInSlotResource::collection($slots), 'Dine-in slots.');
    }

    public function store(Request $request)
    {
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        $validator = Validator::make($request->all(), [
            'day_of_week' => ['required', 'integer', Rule::in([0, 1, 2, 3, 4, 5, 6])],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'seat_capacity' => ['nullable', 'integer', 'min:1', 'max:500'],
            'status' => ['nullable', 'integer', Rule::in([0, 1])],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        try {
            $slot = $this->dineInSlotService->createSlot($kitchen, $validator->validated());
        } catch (InvalidArgumentException $e) {
            return $this->responser([], $e->getMessage(), 422);
        }

        return $this->responser(new DineInSlotResource($slot), 'Dine-in slot created.', 201);
    }

    public function update(Request $request, int $id)
    {
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        $slot = DineInSlot::query()
            ->where('mikitchn_id', $kitchen->id)
            ->find($id);

        if (! $slot) {
            return $this->responser([], 'Dine-in slot not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'day_of_week' => ['nullable', 'integer', Rule::in([0, 1, 2, 3, 4, 5, 6])],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i', 'after:start_time'],
            'seat_capacity' => ['nullable', 'integer', 'min:1', 'max:500'],
            'status' => ['nullable', 'integer', Rule::in([0, 1])],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        try {
            $slot = $this->dineInSlotService->updateSlot($slot, $validator->validated());
        } catch (InvalidArgumentException $e) {
            return $this->responser([], $e->getMessage(), 422);
        }

        return $this->responser(new DineInSlotResource($slot), 'Dine-in slot updated.');
    }

    public function destroy(int $id)
    {
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        $slot = DineInSlot::query()
            ->where('mikitchn_id', $kitchen->id)
            ->find($id);

        if (! $slot) {
            return $this->responser([], 'Dine-in slot not found.', 404);
        }

        $hardDeleted = $this->dineInSlotService->deleteSlot($slot);

        $message = $hardDeleted
            ? 'Dine-in slot deleted.'
            : 'Slot disabled (active bookings exist).';

        return $this->responser([], $message);
    }

    public function sync(Request $request)
    {
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        $validator = Validator::make($request->all(), [
            'slots' => ['required', 'array'],
            'slots.*.day_of_week' => ['required', 'integer', Rule::in([0, 1, 2, 3, 4, 5, 6])],
            'slots.*.start_time' => ['required', 'date_format:H:i'],
            'slots.*.end_time' => ['required', 'date_format:H:i', 'after:slots.*.start_time'],
            'slots.*.seat_capacity' => ['nullable', 'integer', 'min:1', 'max:500'],
            'slots.*.status' => ['nullable', 'integer', Rule::in([0, 1])],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        try {
            $this->dineInSlotService->syncKitchenSlots($kitchen, $validator->validated()['slots']);
        } catch (InvalidArgumentException $e) {
            return $this->responser([], $e->getMessage(), 422);
        }

        $slots = $kitchen->fresh()->dineInSlots()->orderBy('day_of_week')->orderBy('start_time')->get();

        return $this->responser(DineInSlotResource::collection($slots), 'Dine-in slots synced.');
    }
}
