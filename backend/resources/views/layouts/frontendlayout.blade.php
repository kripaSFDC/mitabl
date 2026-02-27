<!doctype html>
<html lang="en">
  @include("includes.frontend.head")
  
  <body>
 
   @include("includes.frontend.header")
   @yield('content')
   @include("includes.frontend.footer")

  <!-- <script src="https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.slim.min.js"></script> -->
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.1/dist/js/bootstrap.bundle.min.js"></script>

  <script>
       $(document).ready(function() {

                var CurrentUrl= document.URL;
                var CurrentUrlEnd = CurrentUrl.split('/').filter(Boolean).pop();
                if (CurrentUrlEnd == window.location.hostname) {
                  $('#home').addClass('active')
                } else {
                  $( "#lu-ID li a" ).each(function() {
                      var ThisUrl = $(this).attr('href');
                      var ThisUrlEnd = ThisUrl.split('/').filter(Boolean).pop();

                      if(ThisUrlEnd == CurrentUrlEnd){
                        $(this).closest('li').addClass('active')
                      }
                  });
                }
                

       });
  </script>
  @stack('scripts')
  </body>
</html>