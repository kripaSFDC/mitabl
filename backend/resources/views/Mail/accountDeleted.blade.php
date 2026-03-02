<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mitabl</title>
    <link rel="stylesheet" href="https://use.typekit.net/nzh0bps.css">

</head>

<body style="max-width: 600px;margin:  0 auto;box-sizing: border-box;font-family: itc-avant-garde-gothic-pro, sans-serif;">
    <div style="width: 100%;float:  left;background-color: #86c2e9;padding: 50px 50px 50px;">
        <div style="background-color:#fff;text-align: center;width: 100%;float:left;padding: 20px 0 0;color: #707070;">
            <img src="https://mitabl.com/frontend/images/logo.png" style="width: 100px;" />
            <h2 style="font-size: 31px;font-weight: 800;margin: 30px 0 50px;">Hello {{$user->first_name.' '.$user->last_name}}</h2>
            <h4 style="font-size: 21px;font-weight: 600;margin-top: 20px;">Your Account @if($user->role_id == 2) and Kitchen @endif Deleted.</h4>
            <p style="font-size: 17px;line-height: 28px;max-width: 330px;margin: 20px auto;">Lorem ipsum dolor sit amet consectetur adipisicing elit. Maxime fugiat voluptate odit harum? Consectetur beatae aut ipsum, ullam, sint non incidunt nihil amet laudantium, aliquid ratione eligendi ipsa cum sunt.</p>
            <h3 style="font-size: 33px;font-weight: bold;margin: 50px 0 50px;">Thank you!</h3>
        </div>




        <footer style="background-color: #0071bc;width: 100%;float: left;text-align: center;padding: 10px 0">
            <div style="width: 100%;float:left;">
                <p style="font-size: 14px;color: #fff;"><a href="https://mitabl.com/terms.html" style="color: #fff;text-decoration: none;">Terms Of Services</a> | <a href="https://mitabl.com/privacy.html" style="color: #fff;text-decoration: none;">Privacy Policy</a> | <a href="https://mitabl.com/about.html"
                        style="color: #fff;text-decoration: none;">About Us</a></p>
            </div>
            <div style="width: 100%;float: left;margin-top: -10px;">
                <p>
                    <a href="https://instagram.com/_mitabl_/" target="_blank" style="color: #fff;margin-right: 10px;"><img src="https://mitabl.com/frontend/images/instagram.png" alt="instagram icon" style="width: 27px;"></a>
                </p>
            </div>
            <div style="width: 100%;float:left;">
                <a href="https://mitabl.com" data-toggle="modal" data-target="#myModal" style="width: 50%;float:left;text-align: right;"><img src="https://mitabl.com/frontend/images/google.png" style="width:100%;max-width: 160px;margin-right: 10px;"></a>
                <a href="https://mitabl.com" data-toggle="modal" data-target="#myModal" style="width: 50%;float:left;text-align: left;"><img src="https://mitabl.com/frontend/images/app.png" style="width:100%;max-width: 160px;margin-left: 10px;"></a>
            </div>
            <div style="width:100%;float: left; text-align: center; color: #fff;font-size: 15px;">
                <p>&copy; 2022 mitabl All rights reserved.</p>
            </div>
        </footer>
    </div>
</body>

</html>