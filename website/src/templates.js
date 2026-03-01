const header = ({ pageTitle }) => `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>${pageTitle}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://use.typekit.net/nzh0bps.css">
    <link rel="stylesheet" href="/frontend/css/bootstrap.min.css">
    <link rel="stylesheet" href="/frontend/css/style.css">
  </head>
  <body>
    <a class="skip-link" href="#main-content">Skip to main content</a>
    <header role="banner">
      <div class="container">
        <nav class="navbar navbar-expand-md navbar-dark" aria-label="Primary">
          <a class="navbar-brand" href="/" aria-label="mitabl home">
            <img src="/frontend/images/logo.png" alt="mitabl logo">
          </a>
          <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#collapsibleNavbar" aria-controls="collapsibleNavbar" aria-expanded="false" aria-label="Toggle navigation menu">
            <span class="navbar-toggler-icon" aria-hidden="true"></span>
          </button>
          <div class="collapse navbar-collapse" id="collapsibleNavbar">
            <ul id="lu-ID" class="navbar-nav ml-auto">
              <li class="nav-item" id="home"><a class="nav-link" href="/">HOME</a></li>
              <li class="nav-item"><a class="nav-link" href="/about">ABOUT</a></li>
              <li class="nav-item"><a class="nav-link" href="/faq">FAQ</a></li>
              <li class="nav-item contact-btn"><a class="nav-link" href="/contact">CONTACT</a></li>
            </ul>
          </div>
        </nav>
      </div>
    </header>
    <main id="main-content" tabindex="-1">
`;

const modal = `
  <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-modal="true" aria-labelledby="comingSoonTitle">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close coming soon dialog">&times;</button>
        </div>
        <div class="modal-body">
          <img src="/frontend/images/rocket.png" alt="Rocket icon for coming soon message">
          <h3 id="comingSoonTitle">Coming Soon...</h3>
          <p>We are preparing something amazing and exciting for you.</p>
        </div>
      </div>
    </div>
  </div>
`;

const footer = ({ showStoreBadges }) => `
    </main>
    <footer role="contentinfo">
      <div class="container">
        <div class="row align-items-center">
          <div class="col-md-6">
            <div class="footer-menu">
              <ul class="d-flex" aria-label="Footer links">
                <li><a href="/terms">Terms</a></li>
                <li><a href="/privacy-policy">Privacy Policy</a></li>
                <li><a href="/contact">Contact</a></li>
              </ul>
            </div>
          </div>
          <div class="col-md-2">
            <div class="footer-logo">
              <a href="/" aria-label="mitabl home"><img src="/frontend/images/logo.png" alt="mitabl logo"></a>
            </div>
          </div>
          <div class="col-md-4">
            <div class="footer-app">
              ${showStoreBadges ? '<a href="#" data-toggle="modal" data-target="#myModal" role="button" aria-label="Open coming soon message for Google Play"><img src="/frontend/images/google.png" alt="Get it on Google Play (coming soon)"></a><a href="#" data-toggle="modal" data-target="#myModal" role="button" aria-label="Open coming soon message for App Store"><img src="/frontend/images/app.png" alt="Download on the App Store (coming soon)"></a>' : '<a href="https://www.instagram.com/mitabl" target="_blank" rel="noopener noreferrer" aria-label="Visit mitabl Instagram (opens in a new tab)">Instagram</a><a href="https://www.linkedin.com/company/mitabl" target="_blank" rel="noopener noreferrer" aria-label="Visit mitabl LinkedIn (opens in a new tab)">LinkedIn</a>'}
            </div>
          </div>
        </div>
      </div>
      <div class="copyright-area text-center"><p>&copy; 2026 mitabl All rights reserved.</p></div>
    </footer>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.1/dist/js/bootstrap.bundle.min.js"></script>
    <script>
      $(document).ready(function() {
        var CurrentUrl= document.URL;
        var CurrentUrlEnd = CurrentUrl.split('/').filter(Boolean).pop();
        if (CurrentUrlEnd === window.location.hostname || window.location.pathname === "/") {
          $('#home').addClass('active')
        } else {
          $("#lu-ID li a").each(function() {
            var ThisUrl = $(this).attr('href');
            var ThisUrlEnd = ThisUrl.split('/').filter(Boolean).pop();
            if(ThisUrlEnd == CurrentUrlEnd){
              $(this).closest('li').addClass('active')
            }
          });
        }

        $('[data-target="#myModal"]').on('click', function(event) {
          if ($(this).attr('href') === '#') {
            event.preventDefault();
          }
        });
      });
    </script>
  </body>
</html>
`;

module.exports = { header, footer, modal };
