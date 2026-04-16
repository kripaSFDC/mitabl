<?php

namespace App\Http\Resources\Order;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderMessage extends JsonResource
{
    public function toArray(Request $request): array
    {
        $authId = auth('api')->id();

        return [
            'id' => $this->id,
            'order_id' => $this->order_id,
            'sender_id' => $this->sender_id,
            'sender_name' => $this->sender
                ? trim($this->sender->first_name . ' ' . $this->sender->last_name)
                : null,
            'body' => $this->body,
            'is_mine' => (int) $this->sender_id === (int) $authId,
            'read_at' => $this->read_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
