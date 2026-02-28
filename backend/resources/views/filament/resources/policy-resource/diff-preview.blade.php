<div class="space-y-4">
    <div class="text-sm text-gray-700 dark:text-gray-300">
        <p>
            Active version:
            <strong>{{ $active?->version ?? 'none' }}</strong>
            |
            Draft version:
            <strong>{{ $draft->version }}</strong>
        </p>
    </div>

    <div class="grid gap-4 md:grid-cols-2">
        <div>
            <h4 class="mb-2 text-sm font-semibold">Active JSON</h4>
            <pre class="max-h-96 overflow-auto rounded bg-gray-100 p-3 text-xs dark:bg-gray-900">{{ $activeJson }}</pre>
        </div>
        <div>
            <h4 class="mb-2 text-sm font-semibold">Draft JSON</h4>
            <pre class="max-h-96 overflow-auto rounded bg-gray-100 p-3 text-xs dark:bg-gray-900">{{ $draftJson }}</pre>
        </div>
    </div>
</div>
