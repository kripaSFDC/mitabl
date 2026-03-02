<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mitabl</title>
    <link rel="stylesheet" href="https://use.typekit.net/nzh0bps.css">

</head>

<body style="max-width: 600px;margin:  0 auto; box-sizing: border-box;font-family: itc-avant-garde-gothic-pro, sans-serif;">
    <div style="width: 100%;float:  left;background-color: #86c2e9;padding: 50px 50px 50px; box-sizing: border-box;">
        <div style="background-color:#fff;text-align: center;width: 100%;float:left;padding: 20px 0 0; box-sizing: border-box; color: #707070;">
            <img src="https://mitabl.com/frontend/images/logo.png" style="width: 100px;" />
            <h2 style="font-size: 31px;font-weight: 800;margin: 30px 0 50px;">Order Reciept</h2>
            <h5 style="font-size: 18px;font-weight: 600;margin-top: 20px;">@if($customer) {{ $order->Mikitchn->name}} kitchen cancel order @else {{ $order->Mikitchn->name}}  Cancel Order @endif</h5>

            <div class="order-head" style="width: 100%; float: left; padding: 0 40px; box-sizing: border-box;">
                <h4 style="width: 50%; float: left; text-align: left; color: #0071bc">Order ID: {{$order->orderId}}</h4>
                <p style="width: 50%; float: left; text-align: right; line-height: 22px;">{{$order->updated_at}}</p>
            </div>

        </div>

        <div style="background-color: #fff; width: 100%; float: left;">
            <div style="padding: 0 40px; box-sizing: border-box;">
                @if($customer)
                    <h3 style="color: #0071bc;">{{$order->Mikitchn->name}}</h3>
                    <p style="color:#707070; line-height: 24px; margin-top: -15px;">{{ $order->Mikitchn->address}}</p>
                @else
                    <h3 style="color: #0071bc;">{{$order->Mikitchn->name}}</h3>
                    <p style="color:#707070; line-height: 24px; margin-top: -15px;">{{ $order->Mikitchn->address}}</p>
                @endif

            </div>

            @if($order->orderdata)
            @foreach($order->orderdata as $orderItems)
                <p style="color: #707070; font-weight: 600; padding: 0 40px; margin-top: 50px;">{{$orderItems->food->food_name}}</p>

                <div style="width: 100%; float: left; padding: 0 40px; box-sizing: border-box; margin-top: -20px;">
                    <p style="width: 50%; float: left; color: #707070;"><span style="background-color:rgba(0, 113, 188, 0.3); color: #0071bc; padding: 3px 5px 1px; border-radius: 3px; border: 1px solid #0071bc;">{{$orderItems->quantity}}</span> x AUD{{$orderItems->food->price}}</p>
                    <p style="width: 50%; float: left; text-align: right; color: #707070;">${{$orderItems->price}}</p>
                </div>

            @endforeach
                
            @endif

            <hr style="color: #707070; opacity: 0.3; height: 0.5px; margin:20px;">

            <div style="width: 100%; float: left; padding: 0 40px; box-sizing: border-box;">
                <p style="width: 50%; float: left; color: #707070; font-weight: 600;">Item Total</p>
                <p style="width: 50%; float: left; text-align: right; color: #707070;">${{$order->item_total_price}}</p>
            </div>
            @if($order->discounted_amount)
            @php
                $discountedPercnt = ($order->discounted_amount / 100) * $order->item_total_price;
                $discountedVal = $order->item_total_price - $discountedPercnt;
            @endphp

            <div style="width: 100%; float: left; padding: 0 40px; box-sizing: border-box; margin-top: -10px;">
                <p style="width: 50%; float: left; color: #707070;">Discount {{$order->discounted_amount}}%</p>
                <p style="width: 50%; float: left; text-align: right; color: #707070;">-${{$discountedVal}}</p>
            </div>
            @endif
            @if($order->taxes)

            <div style="width: 100%; float: left; padding: 0 40px; box-sizing: border-box; margin-top: -20px;">
                <p style="width: 50%; float: left; color: #707070;">GST</p>
                <p style="width: 50%; float: left; text-align: right; color: #707070;">${{$order->taxes}}</p>
            </div>
            @endif

            <div style="width: 84%; float: left; padding: 0 10px; box-sizing: border-box; margin: 5px 7% 20px; background-color:rgba(0, 113, 188, 0.2); color: #0071bc; border-radius: 3px; border: 1px solid #0071bc;">
                <p style="width: 50%; float: left; color: #0071bc; font-weight: 600;">Grand Total</p>
                <p style="width: 50%; float: left; text-align: right; color: #0071bc; font-weight: 600;">${{$order->total_price}}</p>
            </div>

            <div style="width: 84%; float: left; padding: 0 10px; box-sizing: border-box; margin: 5px 7% 50px; background-color:rgba(255, 0, 0, 0.2); color: #FF0000; border-radius: 3px; border: 1px solid #FF0000;">
                @php
                    $discountedValRfnd = ($refundAmount / 100) * $order->total_price;
                @endphp

                <p style="width: 50%; float: left; color: #FF0000; font-weight: 600;">Refund Amount</p>
                <p style="width: 50%; float: left; text-align: right; color: #FF0000; font-weight: 600;">${{$discountedValRfnd}}</p>
            </div>



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
                <a href="https://mitabl.xcelanceweb.com/#" data-toggle="modal" data-target="#myModal" style="width: 50%;float:left;text-align: right;"><img src="https://mitabl.com/frontend/images/google.png" style="width:100%;max-width: 160px;margin-right: 10px;"></a>
                <a href="https://mitabl.xcelanceweb.com/#" data-toggle="modal" data-target="#myModal" style="width: 50%;float:left;text-align: left;"><img src="https://mitabl.com/frontend/images/app.png" style="width:100%;max-width: 160px;margin-left: 10px;"></a>
            </div>
            <div style="width:100%;float: left; text-align: center; color: #fff;font-size: 15px;">
                <p>&copy; 2022 mitabl All rights reserved.</p>
            </div>
        </footer>
    </div>
</body>

</html>