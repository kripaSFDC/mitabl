<?php

namespace Tests\Unit;

use App\Services\AdminRedirectUrlResolver;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;

class AdminRedirectUrlResolverTest extends TestCase
{
    public function test_it_rejects_intended_urls_with_non_canonical_ports(): void
    {
        Config::set('app.url', 'https://www.mitabl.com');

        $resolver = new AdminRedirectUrlResolver();

        session(['url.intended' => 'https://www.mitabl.com:8443/admin/orders']);

        $this->assertSame('https://www.mitabl.com/admin', $resolver->resolveFromSession());
        $this->assertNull(session('url.intended'));
    }

    public function test_it_preserves_safe_admin_paths_on_the_canonical_origin(): void
    {
        Config::set('app.url', 'https://www.mitabl.com');

        $resolver = new AdminRedirectUrlResolver();

        session(['url.intended' => 'https://www.mitabl.com/admin/orders?status=open']);

        $this->assertSame(
            'https://www.mitabl.com/admin/orders?status=open',
            $resolver->resolveFromSession(),
        );
    }

    public function test_it_rejects_non_admin_intended_paths(): void
    {
        Config::set('app.url', 'https://www.mitabl.com');

        $resolver = new AdminRedirectUrlResolver();

        session(['url.intended' => 'https://www.mitabl.com/profile']);

        $this->assertSame('https://www.mitabl.com/admin', $resolver->resolveFromSession());
    }
}
