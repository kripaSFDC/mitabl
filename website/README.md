Marketing Website
=================

## Setup Steps 

Setup steps:

PLease empty your directory and database then follow these steps:

1.clone this respository. (1 time command)

2.run command "composer install & npm install". (1 time command)

3.create .env file with command " cp .env.example .env " (1 time command)

4.change database credentials in ".env" file. (For connection with database. 1 time changes.)

5.to generate application key run command "php artisan key:generate". (For generate unique key of application. 1 time changes.)


6.run command "php artisan optimize:clear ". (For clear application cache of db,routes etc. run with every pull)

7.run command "composer dump-autoload". (1 time command)


8.To give read/write permissions to "storage & bootstrap & public" folders run command "chmod -R 777 storage" & "chmod -R 777 bootstrap" & "chmod -R 777 public". (1 time command)



9.please bind your hosting url to public folder.  (1 time command)
		
			Or

If you test on localhost then run "php artisan serve" its serve application on port 8000 

