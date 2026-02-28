Hi {{ $ticket->requester_name ?: 'there' }},

@if($isAcknowledgement)
Thanks for contacting mitabl support. Your ticket has been created.
@else
There is an update on your support ticket.
@endif

Ticket Number: {{ $ticket->ticket_number }}
Subject: {{ $ticket->subject }}
Status: {{ $ticket->status }}

@if(!$isAcknowledgement && $messageBody)
Reply:
{{ $messageBody }}
@endif

You can reply from the app or contact our team and reference this ticket number.
