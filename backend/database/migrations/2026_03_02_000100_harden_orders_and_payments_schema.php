<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        $this->convertMonetaryColumnsToDecimal();
        $this->alignForeignKeyColumnTypes();
        $this->cleanupOrphanRows();
        $this->addIndexes();
        $this->addForeignKeys();
    }

    public function down(): void
    {
        $this->dropForeignKeys();
        $this->dropIndexes();
    }

    private function convertMonetaryColumnsToDecimal(): void
    {
        Schema::table('foods', function (Blueprint $table): void {
            if (Schema::hasColumn('foods', 'price')) {
                $table->decimal('price', 12, 2)->change();
            }
        });

        Schema::table('orders', function (Blueprint $table): void {
            if (Schema::hasColumn('orders', 'item_total_price')) {
                $table->decimal('item_total_price', 12, 2)->change();
            }
            if (Schema::hasColumn('orders', 'taxes')) {
                $table->decimal('taxes', 12, 2)->nullable()->change();
            }
            if (Schema::hasColumn('orders', 'total_price')) {
                $table->decimal('total_price', 12, 2)->change();
            }
            if (Schema::hasColumn('orders', 'discounted_amount')) {
                $table->decimal('discounted_amount', 12, 2)->nullable()->change();
            }
        });

        Schema::table('order_data', function (Blueprint $table): void {
            if (Schema::hasColumn('order_data', 'price')) {
                $table->decimal('price', 12, 2)->change();
            }
        });

        Schema::table('payments', function (Blueprint $table): void {
            if (Schema::hasColumn('payments', 'amount')) {
                $table->decimal('amount', 12, 2)->change();
            }
        });

        Schema::table('refunds', function (Blueprint $table): void {
            if (Schema::hasColumn('refunds', 'amount')) {
                $table->decimal('amount', 12, 2)->change();
            }
        });

        Schema::table('transfers', function (Blueprint $table): void {
            if (Schema::hasColumn('transfers', 'amount')) {
                $table->decimal('amount', 12, 2)->change();
            }
        });
    }

    private function alignForeignKeyColumnTypes(): void
    {
        Schema::table('orders', function (Blueprint $table): void {
            if (Schema::hasColumn('orders', 'mikitchn_id')) {
                $table->unsignedBigInteger('mikitchn_id')->change();
            }
            if (Schema::hasColumn('orders', 'user_id')) {
                $table->unsignedBigInteger('user_id')->change();
            }
        });

        Schema::table('foods', function (Blueprint $table): void {
            if (Schema::hasColumn('foods', 'restaurant_id')) {
                $table->unsignedBigInteger('restaurant_id')->change();
            }
        });

        Schema::table('order_data', function (Blueprint $table): void {
            if (Schema::hasColumn('order_data', 'order_id')) {
                $table->unsignedBigInteger('order_id')->change();
            }
            if (Schema::hasColumn('order_data', 'food_id')) {
                $table->unsignedBigInteger('food_id')->change();
            }
        });

        Schema::table('payments', function (Blueprint $table): void {
            if (Schema::hasColumn('payments', 'order_id')) {
                $table->unsignedBigInteger('order_id')->change();
            }
        });

        Schema::table('transfers', function (Blueprint $table): void {
            if (Schema::hasColumn('transfers', 'order_id')) {
                $table->unsignedBigInteger('order_id')->change();
            }
            if (Schema::hasColumn('transfers', 'kitchen_id')) {
                $table->unsignedBigInteger('kitchen_id')->change();
            }
        });

        Schema::table('refunds', function (Blueprint $table): void {
            if (Schema::hasColumn('refunds', 'order_id')) {
                $table->unsignedBigInteger('order_id')->change();
            }
            if (Schema::hasColumn('refunds', 'user_id')) {
                $table->unsignedBigInteger('user_id')->change();
            }
        });
    }

    private function cleanupOrphanRows(): void
    {
        DB::table('order_data')
            ->leftJoin('orders', 'orders.id', '=', 'order_data.order_id')
            ->whereNull('orders.id')
            ->delete();

        DB::table('order_data')
            ->leftJoin('foods', 'foods.id', '=', 'order_data.food_id')
            ->whereNull('foods.id')
            ->delete();

        DB::table('payments')
            ->leftJoin('orders', 'orders.id', '=', 'payments.order_id')
            ->whereNull('orders.id')
            ->delete();

        DB::table('orders')
            ->leftJoin('users', 'users.id', '=', 'orders.user_id')
            ->whereNull('users.id')
            ->delete();

        DB::table('orders')
            ->leftJoin('mikitchns', 'mikitchns.id', '=', 'orders.mikitchn_id')
            ->whereNull('mikitchns.id')
            ->delete();
    }

    private function addIndexes(): void
    {
        if (! $this->indexExists('orders', 'orders_user_status_date_idx')) {
            Schema::table('orders', fn (Blueprint $table) => $table->index(['user_id', 'status', 'delivery_date'], 'orders_user_status_date_idx'));
        }

        if (! $this->indexExists('orders', 'orders_kitchen_status_date_idx')) {
            Schema::table('orders', fn (Blueprint $table) => $table->index(['mikitchn_id', 'status', 'delivery_date'], 'orders_kitchen_status_date_idx'));
        }

        if (! $this->indexExists('orders', 'orders_date_time_idx')) {
            Schema::table('orders', fn (Blueprint $table) => $table->index(['delivery_date', 'delivery_time_from', 'delivery_time_to'], 'orders_date_time_idx'));
        }

        if (! $this->indexExists('payments', 'payments_order_id_idx')) {
            Schema::table('payments', fn (Blueprint $table) => $table->index('order_id', 'payments_order_id_idx'));
        }

        if (! $this->indexExists('payments', 'payments_payment_id_idx')) {
            Schema::table('payments', fn (Blueprint $table) => $table->index('payment_id', 'payments_payment_id_idx'));
        }

        if (! $this->indexExists('order_data', 'order_data_order_id_idx')) {
            Schema::table('order_data', fn (Blueprint $table) => $table->index('order_id', 'order_data_order_id_idx'));
        }

        if (! $this->indexExists('order_data', 'order_data_food_id_idx')) {
            Schema::table('order_data', fn (Blueprint $table) => $table->index('food_id', 'order_data_food_id_idx'));
        }

        if (! $this->indexExists('foods', 'foods_restaurant_id_idx')) {
            Schema::table('foods', fn (Blueprint $table) => $table->index('restaurant_id', 'foods_restaurant_id_idx'));
        }
    }

    private function addForeignKeys(): void
    {
        if (! $this->foreignKeyExists('orders', 'orders_user_id_fk')) {
            Schema::table('orders', fn (Blueprint $table) => $table->foreign('user_id', 'orders_user_id_fk')->references('id')->on('users')->cascadeOnDelete());
        }

        if (! $this->foreignKeyExists('orders', 'orders_mikitchn_id_fk')) {
            Schema::table('orders', fn (Blueprint $table) => $table->foreign('mikitchn_id', 'orders_mikitchn_id_fk')->references('id')->on('mikitchns')->cascadeOnDelete());
        }

        if (! $this->foreignKeyExists('foods', 'foods_restaurant_id_fk')) {
            Schema::table('foods', fn (Blueprint $table) => $table->foreign('restaurant_id', 'foods_restaurant_id_fk')->references('id')->on('mikitchns')->cascadeOnDelete());
        }

        if (! $this->foreignKeyExists('order_data', 'order_data_order_id_fk')) {
            Schema::table('order_data', fn (Blueprint $table) => $table->foreign('order_id', 'order_data_order_id_fk')->references('id')->on('orders')->cascadeOnDelete());
        }

        if (! $this->foreignKeyExists('order_data', 'order_data_food_id_fk')) {
            Schema::table('order_data', fn (Blueprint $table) => $table->foreign('food_id', 'order_data_food_id_fk')->references('id')->on('foods')->cascadeOnDelete());
        }

        if (! $this->foreignKeyExists('payments', 'payments_order_id_fk')) {
            Schema::table('payments', fn (Blueprint $table) => $table->foreign('order_id', 'payments_order_id_fk')->references('id')->on('orders')->cascadeOnDelete());
        }
    }

    private function dropForeignKeys(): void
    {
        Schema::table('payments', function (Blueprint $table): void {
            if ($this->foreignKeyExists('payments', 'payments_order_id_fk')) {
                $table->dropForeign('payments_order_id_fk');
            }
        });

        Schema::table('order_data', function (Blueprint $table): void {
            if ($this->foreignKeyExists('order_data', 'order_data_order_id_fk')) {
                $table->dropForeign('order_data_order_id_fk');
            }
            if ($this->foreignKeyExists('order_data', 'order_data_food_id_fk')) {
                $table->dropForeign('order_data_food_id_fk');
            }
        });

        Schema::table('foods', function (Blueprint $table): void {
            if ($this->foreignKeyExists('foods', 'foods_restaurant_id_fk')) {
                $table->dropForeign('foods_restaurant_id_fk');
            }
        });

        Schema::table('orders', function (Blueprint $table): void {
            if ($this->foreignKeyExists('orders', 'orders_user_id_fk')) {
                $table->dropForeign('orders_user_id_fk');
            }
            if ($this->foreignKeyExists('orders', 'orders_mikitchn_id_fk')) {
                $table->dropForeign('orders_mikitchn_id_fk');
            }
        });
    }

    private function dropIndexes(): void
    {
        Schema::table('foods', function (Blueprint $table): void {
            if ($this->indexExists('foods', 'foods_restaurant_id_idx')) {
                $table->dropIndex('foods_restaurant_id_idx');
            }
        });

        Schema::table('order_data', function (Blueprint $table): void {
            if ($this->indexExists('order_data', 'order_data_order_id_idx')) {
                $table->dropIndex('order_data_order_id_idx');
            }
            if ($this->indexExists('order_data', 'order_data_food_id_idx')) {
                $table->dropIndex('order_data_food_id_idx');
            }
        });

        Schema::table('payments', function (Blueprint $table): void {
            if ($this->indexExists('payments', 'payments_order_id_idx')) {
                $table->dropIndex('payments_order_id_idx');
            }
            if ($this->indexExists('payments', 'payments_payment_id_idx')) {
                $table->dropIndex('payments_payment_id_idx');
            }
        });

        Schema::table('orders', function (Blueprint $table): void {
            if ($this->indexExists('orders', 'orders_user_status_date_idx')) {
                $table->dropIndex('orders_user_status_date_idx');
            }
            if ($this->indexExists('orders', 'orders_kitchen_status_date_idx')) {
                $table->dropIndex('orders_kitchen_status_date_idx');
            }
            if ($this->indexExists('orders', 'orders_date_time_idx')) {
                $table->dropIndex('orders_date_time_idx');
            }
        });
    }

    private function indexExists(string $table, string $index): bool
    {
        if (! $this->supportsInformationSchemaLookups()) {
            return false;
        }

        $result = DB::selectOne(
            'SELECT COUNT(1) AS aggregate FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = ? AND index_name = ?',
            [$table, $index]
        );

        return ((int) ($result->aggregate ?? 0)) > 0;
    }

    private function foreignKeyExists(string $table, string $constraint): bool
    {
        if (! $this->supportsInformationSchemaLookups()) {
            return false;
        }

        $result = DB::selectOne(
            'SELECT COUNT(1) AS aggregate FROM information_schema.table_constraints WHERE table_schema = DATABASE() AND table_name = ? AND constraint_name = ? AND constraint_type = "FOREIGN KEY"',
            [$table, $constraint]
        );

        return ((int) ($result->aggregate ?? 0)) > 0;
    }

    private function supportsInformationSchemaLookups(): bool
    {
        $driver = DB::connection()->getDriverName();

        return in_array($driver, ['mysql', 'mariadb'], true);
    }
};
