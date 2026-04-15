<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Order;
use App\Models\CompletedOrder;
use Carbon\Carbon;
use App\Events\MakeOrderPaymentToVendor;

class OrderPaymentCron extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'orderpayment:cron';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command for order payment to vendor';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $cOrders = CompletedOrder::where('completed',0)->where('completed_date_time','<=',Carbon::now()->subDay())->get();

        foreach ($cOrders as $key => $cOrder) {
            event(new MakeOrderPaymentToVendor($cOrder));
        }

        return 0;
    }
}
