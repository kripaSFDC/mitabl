<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SpecialDiet;

class SpecialDietsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        SpecialDiet::truncate();

        $specialDiet =  [
            [
              'name' => 'Italian'
            ],
            [
              'name' => 'Thai'
            ],
            [
              'name' => 'French'
            ],
            [
              'name' => 'Japanese'
            ],[
              'name' => 'Lebanese'
            ],[
              'name' => 'Spanish'
            ],[
              'name' => 'German'
            ],[
              'name' => 'Korean'
            ],[
              'name' => 'Caribbean'
            ],[
              'name' => 'Greek'
            ],[
              'name' => 'Filipino'
            ],[
              'name' => 'Indian'
            ],[
              'name' => 'Mexican'
            ],[
              'name' => 'Indonesian'
            ],[
              'name' => 'Brazilian'
            ],[
              'name' => 'Chinese'
            ],[
              'name' => 'American'
            ],[
              'name' => 'African'
            ],[
              'name' => 'Malaysian'
            ],[
              'name' => 'Irish'
            ],[
              'name' => 'Turkish'
            ],[
              'name' => 'Israeli'
            ],[
              'name' => 'Others'
            ],
          ];

          SpecialDiet::insert($specialDiet);
    }
}
