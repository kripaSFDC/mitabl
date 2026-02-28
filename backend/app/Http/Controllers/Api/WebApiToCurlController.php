<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PreRegistration;
use App\Models\SupportTicket;
use App\Services\PreRegistrationService;
use App\Services\SupportTicketService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class WebApiToCurlController extends Controller
{
    public $data = [];

    public function __construct(
        private PreRegistrationService $preRegistrationService,
        private SupportTicketService $supportTicketService
    ) {
    }

    public function preRegister(Request $request)
    {
        $normalized = $this->normalizePreRegisterPayload($request->all());
        $request->merge([
            'first_name' => $normalized['FirstName'] ?? ($normalized['first_name'] ?? null),
            'last_name' => $normalized['LastName'] ?? ($normalized['last_name'] ?? null),
            'email' => $normalized['Email'] ?? ($normalized['email'] ?? null),
            'mobile' => $normalized['MobilePhone'] ?? ($normalized['mobile'] ?? null),
            'city' => $normalized['City'] ?? ($normalized['city'] ?? null),
            '00N5i000006uZtT' => $normalized['mitabl_Interested_In__c'] ?? ($normalized['00N5i000006uZtT'] ?? null),
        ]);

        $honeypotField = (string) config('support.honeypot_field', 'website');
        $validated = $request->validate([
            'first_name' => ['nullable', 'string', 'max:255'],
            'last_name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'mobile' => ['nullable', 'string', 'max:40'],
            'city' => ['nullable', 'string', 'max:120'],
            '00N5i000006uZtT' => ['nullable', 'string', 'max:120'],
            'consent_to_contact' => ['nullable', 'boolean'],
            $honeypotField => ['nullable', 'string', 'max:255'],
        ]);

        if (! empty($validated[$honeypotField] ?? null)) {
            return $this->responser(['accepted' => true], 'Your Registration Created Successfully');
        }

        $result = $this->preRegistrationService->create([
            'first_name' => $normalized['FirstName'] ?? null,
            'last_name' => $normalized['LastName'] ?? null,
            'email' => $normalized['Email'] ?? null,
            'phone' => $normalized['MobilePhone'] ?? null,
            'city' => $normalized['City'] ?? null,
            'interested_as' => $normalized['mitabl_Interested_In__c'] ?? 'foodie',
            'consent_to_contact' => (bool) ($normalized['consent_to_contact'] ?? true),
        ], 'preregister_api');

        /** @var PreRegistration $registration */
        $registration = $result['registration'];

        return $this->responser([
            'id' => $registration->id,
            'status' => $registration->status,
            'duplicate' => $result['duplicate'],
        ], 'Your Registration Created Successfully');
    }

    public function mobContact(Request $request)
    {
        $normalized = $this->normalizeMobContactPayload($request->all());
        $request->merge([
            'email' => $normalized['SuppliedEmail'] ?? ($normalized['email'] ?? null),
            'subject' => $normalized['Subject'] ?? ($normalized['subject'] ?? null),
            'description' => $normalized['Description'] ?? ($normalized['description'] ?? null),
            'type' => $normalized['Type'] ?? ($normalized['type'] ?? null),
            'phone' => $normalized['SuppliedPhone'] ?? ($normalized['phone'] ?? null),
            'recordType' => $normalized['mitabl_Case_For__c'] ?? ($normalized['recordType'] ?? null),
            '00N5i000009zQqb' => $normalized['mitabl_micook_Id__c'] ?? ($normalized['00N5i000009zQqb'] ?? null),
            '00N5i000009zQxr' => $normalized['mitabl_Mifoodi_Id__c'] ?? ($normalized['00N5i000009zQxr'] ?? null),
            '00N5i000006ubH5' => $normalized['mitabl_Order_Id__c'] ?? ($normalized['00N5i000006ubH5'] ?? null),
        ]);

        $honeypotField = (string) config('support.honeypot_field', 'website');
        $validated = $request->validate([
            'email' => ['required', 'email', 'max:255'],
            'subject' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'min:5'],
            'type' => ['nullable', 'string', 'max:120'],
            'phone' => ['nullable', 'string', 'max:40'],
            'recordType' => ['nullable', 'string', 'max:120'],
            'priority' => ['nullable', Rule::in(SupportTicket::priorities())],
            '00N5i000009zQqb' => ['nullable', 'integer'],
            '00N5i000009zQxr' => ['nullable', 'integer'],
            '00N5i000006ubH5' => ['nullable', 'integer'],
            $honeypotField => ['nullable', 'string', 'max:255'],
        ]);

        if (! empty($validated[$honeypotField] ?? null)) {
            return $this->responser(['accepted' => true], 'Contact Message Sent Successfully');
        }

        $category = $normalized['Type'] ?? ($normalized['mitabl_Case_For__c'] ?? 'general');
        $source = 'mobcontact_api';

        $result = $this->supportTicketService->createTicket([
            'requester_name' => null,
            'requester_email' => $normalized['SuppliedEmail'] ?? '',
            'requester_phone' => $normalized['SuppliedPhone'] ?? null,
            'subject' => $normalized['Subject'] ?? 'Support request',
            'description' => $normalized['Description'] ?? '',
            'category' => $category,
            'priority' => $validated['priority'] ?? SupportTicket::PRIORITY_NORMAL,
            'order_id' => $normalized['mitabl_Order_Id__c'] ?? null,
            'mikitchn_id' => $normalized['mitabl_micook_Id__c'] ?? null,
            'user_id' => $normalized['mitabl_Mifoodi_Id__c'] ?? null,
            'actor_type' => 'guest',
            'actor_id' => null,
        ], $source);

        /** @var SupportTicket $ticket */
        $ticket = $result['ticket'];

        return $this->responser([
            'id' => $ticket->id,
            'ticket_number' => $ticket->ticket_number,
            'status' => $ticket->status,
            'duplicate' => $result['duplicate'],
        ], 'Contact Message Sent Successfully');
    }

    private function normalizePreRegisterPayload(array $payload): array
    {
        if (!isset($payload['FirstName']) && isset($payload['first_name'])) {
            $payload['FirstName'] = $payload['first_name'];
        }
        if (!isset($payload['LastName']) && isset($payload['last_name'])) {
            $payload['LastName'] = $payload['last_name'];
        }
        if (!isset($payload['Email']) && isset($payload['email'])) {
            $payload['Email'] = $payload['email'];
        }
        if (!isset($payload['MobilePhone']) && isset($payload['mobile'])) {
            $payload['MobilePhone'] = $payload['mobile'];
        }
        if (!isset($payload['City']) && isset($payload['city'])) {
            $payload['City'] = $payload['city'];
        }
        if (!isset($payload['mitabl_Interested_In__c']) && isset($payload['00N5i000006uZtT'])) {
            $payload['mitabl_Interested_In__c'] = $payload['00N5i000006uZtT'];
        }
        if (! isset($payload['mobile']) && isset($payload['phone'])) {
            $payload['mobile'] = $payload['phone'];
        }
        if (! isset($payload['MobilePhone']) && isset($payload['phone'])) {
            $payload['MobilePhone'] = $payload['phone'];
        }
        if (! isset($payload['consent_to_contact'])) {
            $payload['consent_to_contact'] = true;
        }

        return $payload;
    }

    private function normalizeMobContactPayload(array $payload): array
    {
        if (!isset($payload['Type']) && isset($payload['type'])) {
            $payload['Type'] = $payload['type'];
        }
        if (!isset($payload['SuppliedEmail']) && isset($payload['email'])) {
            $payload['SuppliedEmail'] = $payload['email'];
        }
        if (!isset($payload['SuppliedPhone']) && isset($payload['phone'])) {
            $payload['SuppliedPhone'] = $payload['phone'];
        }
        if (!isset($payload['Subject']) && isset($payload['subject'])) {
            $payload['Subject'] = $payload['subject'];
        }
        if (!isset($payload['Description']) && isset($payload['description'])) {
            $payload['Description'] = $payload['description'];
        }
        if (!isset($payload['mitabl_Case_For__c']) && isset($payload['recordType'])) {
            $payload['mitabl_Case_For__c'] = $payload['recordType'];
        }
        if (!isset($payload['mitabl_micook_Id__c']) && isset($payload['00N5i000009zQqb'])) {
            $payload['mitabl_micook_Id__c'] = $payload['00N5i000009zQqb'];
        }
        if (!isset($payload['mitabl_Mifoodi_Id__c']) && isset($payload['00N5i000009zQxr'])) {
            $payload['mitabl_Mifoodi_Id__c'] = $payload['00N5i000009zQxr'];
        }
        if (!isset($payload['mitabl_Order_Id__c']) && isset($payload['00N5i000006ubH5'])) {
            $payload['mitabl_Order_Id__c'] = $payload['00N5i000006ubH5'];
        }

        return $payload;
    }

}
