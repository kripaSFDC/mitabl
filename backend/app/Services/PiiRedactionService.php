<?php

namespace App\Services;

use Illuminate\Support\Str;

class PiiRedactionService
{
    public function redact(string $value): string
    {
        if (! (bool) config('support.pii_redaction.enabled', true)) {
            return $value;
        }

        $redacted = $value;

        // Email addresses.
        $redacted = (string) preg_replace('/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i', '[redacted-email]', $redacted);

        // Phone-like sequences (7+ digits with separators).
        $redacted = (string) preg_replace('/\b(?:\+?\d[\d\s().-]{6,}\d)\b/', '[redacted-phone]', $redacted);

        // Potential card-like long numeric sequences.
        $redacted = (string) preg_replace('/\b\d{12,19}\b/', '[redacted-number]', $redacted);

        // OAuth/JWT/API tokens.
        $redacted = (string) preg_replace('/\b(?:Bearer\s+)?[A-Za-z0-9_-]{24,}\.[A-Za-z0-9._-]{10,}\b/', '[redacted-token]', $redacted);

        return Str::limit($redacted, 4000, '');
    }
}
