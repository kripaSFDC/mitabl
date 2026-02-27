<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400"></a></p>

<p align="center">
<a href="https://travis-ci.org/laravel/framework"><img src="https://travis-ci.org/laravel/framework.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects, such as:

- [Simple, fast routing engine](https://laravel.com/docs/routing).
- [Powerful dependency injection container](https://laravel.com/docs/container).
- Multiple back-ends for [session](https://laravel.com/docs/session) and [cache](https://laravel.com/docs/cache) storage.
- Expressive, intuitive [database ORM](https://laravel.com/docs/eloquent).
- Database agnostic [schema migrations](https://laravel.com/docs/migrations).
- [Robust background job processing](https://laravel.com/docs/queues).
- [Real-time event broadcasting](https://laravel.com/docs/broadcasting).

Laravel is accessible, powerful, and provides tools required for large, robust applications.

## Setup Steps 

Setup steps:

PLease empty your directory and database then follow these steps:

1.clone this respository. (1 time command)

2.run command "composer update & npm install". (1 time command)

3.create .env file with command " cp .env.example .env " (1 time command)

4.change database credentials in ".env" file. (For connection with database. 1 time changes.)

5.to generate application key run command "php artisan key:generate". (For generate unique key of application. 1 time changes.)

6.run command "php artisan jwt:secret". (For generate unique key of JWT. 1 time changes.)

7.run command "php artisan migrate". (For apply any updation in database.run with every pull)

8.run command "php artisan optimize:clear ". (For clear application cache of db,routes etc. run with every pull)

9.run command "composer dump-autoload". (1 time command)

10.run command "php artisan db:seed". (For add rquired data in database tables. run with every pull)

11.To give read/write permissions to "storage & bootstrap & public" folders run command "chmod -R 777 storage" & "chmod -R 777 bootstrap" & "chmod -R 777 public". (1 time command)



12.please bind your hosting url to public folder.  (1 time command)
		
			Or

If you test on localhost then run "php artisan serve" its serve application on port 8000 

