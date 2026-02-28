<p>Hi {{ $user->first_name ?? $user->name ?? 'there' }},</p>

<p>Your kitchen certificate has been approved.</p>

<p>
    Certificate Number: {{ $certificate->certificate_no }}<br>
    Kitchen: {{ optional($certificate->mikitchn)->name ?? 'N/A' }}
</p>

<p>You can continue managing your kitchen and bookings in the app.</p>

<p>Regards,<br>mitabl Team</p>
