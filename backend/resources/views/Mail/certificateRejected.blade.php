<p>Hi {{ $user->first_name ?? $user->name ?? 'there' }},</p>

<p>Your kitchen certificate submission was reviewed and rejected.</p>

<p>
    Certificate Number: {{ $certificate->certificate_no }}<br>
    Kitchen: {{ optional($certificate->mikitchn)->name ?? 'N/A' }}
</p>

<p><strong>Reason:</strong> {{ $certificate->rejection_reason ?: 'No reason provided.' }}</p>

<p>Please update the details/documents and submit again.</p>

<p>Regards,<br>mitabl Team</p>
