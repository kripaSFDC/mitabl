<!DOCTYPE html>
<html lang="en">
<head>
  <title>Mitabl</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@100;200;300;400;500&display=swap" rel="stylesheet">
  <style type="text/css">
    *{
      box-sizing: border-box;
      font-family: 'Poppins', sans-serif;
    }
    .main-section img {
        max-width: 150px;
        margin: 0 auto;
    }
    .main-section {
        text-align: center;
        display: flex;
        flex-wrap: wrap;
        height: 100vh;
        justify-content: center;
      background: url(https://mitabl.com/frontend/background.jpg) 0 0 no-repeat;
        background-position: bottom;
        padding-top: 2%;
        position: relative;
    }
    body {
        margin: 0;
    }
    .content pre {
        font-size: 18px;
        color: #fff;
    }
    .content {
        position: relative;
        z-index: 1;
    }
    .main-section:before {
        content: "";
        background: rgb(0 0 0 / 71%);
        position: absolute;
        width: 100%;
        height: 100%;
        top: 0;
    }

    @media screen and (max-width: 1600px){
      .content pre {
          font-size: 16px;
      }
    }
  </style>
</head>
<body>

<div class="main-section">
  <div class="content">
    <a href="#"><img src="https://mitabl.com/frontend/logo.png"></a>
    <pre>
      mitabl, creating opportunities 
      mitabl, reducing food wastage
      mitabl, building communities
      mitabl, making dreams a reality

      mitabl is designed to work with you and for you to create a place where we come together to break some bread, 
      this is an idea that we all share our culture and food with smile and love
      mitabl is here to bring personalisation to the way we dine
      mitabl is the place where you get real home cooked meals
  </pre>
  </div>
</div>

</body>
</html>
