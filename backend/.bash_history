ls
cd public/
ls
vi /etc/httpd/conf.d/imrnext.xcelanceweb.com.conf 
su
ls
npm install
php artisan
php artisan migrate
php artisan optimize:clear
php artisan migrate
php artisan key:generate
php artisan optimize:clear
php artisan migrate
php artisan -v
php artisan migrate:rollback
composer require darkaonline/l5-swagger
php artisan vendor:publish --provider "L5Swagger\L5SwaggerServiceProvider"
php artisan l5-swagger:generate
php artisan optimize:clear
php artisan l5-swagger:generate
php artisan migrate
php artisan optimize:clear
php artisan migrate
php artisan make:model Role
php artisan make:model User
php artisan l5-swagger:generate
composer require tymon/jwt-auth
php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
php artisan jwt:secret
php artisan make:middleware JwtMiddleware
php artisan l5-swagger:generate
php artisan make:model verifyOtp -mr
php artisan migrate
php artisan make:mail sendOTP
php artisan l5-swagger:generate
composer require laravel/cashier
composer require stripe/stripe-php
php artisan make:Mikitchn -mcr
php artisan make:model Mikitchn -mcr
php artisan migrate
php artisan l5-swagger:generate
php artisan make:controller API/ForgotPasswordController
php artisan make:controller API/ResetPasswordController
php artisan make:notification MailResetPasswordNotification
php artisan make:notification InvoicePaid
php artisan l5-swagger:generate
php artisan vendor:publish --tag=laravel-notifications
php artisan make:controller Api/FoodController -mcr
php artisan make:model Foods -mcr
php artisan make:model CookingStyles --migration
php artisan make:model SpecialDiet --migration
php artisan migrate
php artisan l5-swagger:generate
php artisan make:middleware Restaurant
php artisan l5-swagger:generate
php artisan optimize:clear
php artisan l5-swagger:generate
php artisan migrate:rollback --step=1
php artisan migrate
php artisan make:seeder CookingStyles
php artisan make:seeder SpecialDiets
php artisan:db seed
php artisan db:seed
php artisan optimize:clear
php artisan db:seed
php artisan make:seeder SpecialDietsSeeder
php artisan make:seeder CookingStylesSeeder
php artisan db:seed
php artisan migration:rollback --step=3
php artisan migrate:rollback --step=3
php artiasn migrate
php artisan migrate
php artisan db:seed
php artisan make:migration add_status_to_foods_table --table=foods
php artisan migrate
php artisan migrate:rollback --step=1
php artisan migrate
php artisan make:resource Restaurant/Restaurant --collection
php artisan make:resource Restaurant/Food --collection
npm -v
node -v
php artisan l5-swagger:generate
php artisan make:migration add_dine_in_to_mikitchns_table --table=mikitchns
php artisan migrate
php artisan migrate:rollback --step=1
php artisan migrate
php artisan l5-swagger:generate
php artisan make:migration add_available_to_mikitchns --table="mikitchns"
php artisan migrate
php artisan make:migration add_avatar_to_users_table --table="users"
php artisan migrate
php artisan make:resource UserCollection
php artisan make:resource User/User --collection
php artisan make:model Review -cm
php artisan migrate
php artisan migrate:rollback --step=1
php artisan migrate
php artisan make:resource Restaurant/Review --collection
php artisan make:migration add_cooking_styles_to_mikitchns_table --table="mikitchns"
composer require overtrue/laravel-favorite -vvv
php artisan vendor:publish
php artisan vendor:publish --provider="Overtrue\LaravelFavorite\FavoriteServiceProvider" --tag="migrations"
php artisan vendor:publish --provider="Overtrue\LaravelFavorite\FavoriteServiceProvider" --tag=migrations
php artisan migrate
composer require overtrue/laravel-favorite -vvv
php artisan vendor:publish --provider="Overtrue\\LaravelFavorite\\FavoriteServiceProvider" --tag=config
php artisan optimize:clear
php artisan vendor:publish --provider="Overtrue\\LaravelFavorite\\FavoriteServiceProvider" --tag=config
php artisan vendor:publish
php artisan migrate
php artisan make:controller Api/FavoriteController
php artisan make:resource User/Favorite --collection
php artisan make:model Order -mcr
php artisan make:model OrderData -migration
php artisan make:model OrderData --migration
php artisan make:model PromoCode --migration
php artisan migrate
php artisan make:resource Order/Order --collection
php artisan make:middleware Customer
