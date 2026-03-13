<?php

namespace Tests\Unit;

use App\Services\AdminRedirectUrlResolver;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;

class AdminRedirectUrlResolverTest extends TestCase
{
    public function test_after_login_it_always_falls_back_to_the_canonical_admin_url(): void
    {
        Config::set('app.url', 'https://www.mitabl.com');

        $resolver = new AdminRedirectUrlResolver();

        session(['url.intended' => 'https://www.mitabl.com:8443/admin/orders']);

        $this->assertSame('https://www.mitabl.com/admin', $resolver->resolveAfterLogin());
        $this->assertNull(session('url.intended'));
    }

    public function test_authenticated_visit_preserves_safe_admin_paths_on_the_canonical_origin(): void
    {
        Config::set('app.url', 'https://www.mitabl.com');

        $resolver = new AdminRedirectUrlResolver();

        session(['url.intended' => 'https://www.mitabl.com/admin/orders?status=open']);

        $this->assertSame(
            'https://www.mitabl.com/admin/orders?status=open',
            $resolver->resolveForAuthenticatedVisit(),
        );
    }

    public function test_authenticated_visit_rejects_non_admin_intended_paths(): void
    {
        Config::set('app.url', 'https://www.mitabl.com');

        $resolver = new AdminRedirectUrlResolver();

        session(['url.intended' => 'https://www.mitabl.com/profile']);

        $this->assertSame('https://www.mitabl.com/admin', $resolver->resolveForAuthenticatedVisit());
    }
}
