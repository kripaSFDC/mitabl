const header = ({ pageTitle }) => `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${pageTitle}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&family=Playfair+Display:ital,wght@0,700;1,700&display=swap" rel="stylesheet">
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        brand: {
                            50: '#fff7ed',
                            100: '#ffedd5',
                            500: '#f97316',
                            600: '#ea580c',
                            700: '#c2410c',
                            900: '#7c2d12',
                        },
                        accent: '#10b981',
                    },
                    fontFamily: {
                        sans: ['Outfit', 'sans-serif'],
                        serif: ['Playfair Display', 'serif'],
                    },
                    animation: {
                        'float': 'float 6s ease-in-out infinite',
                        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                    },
                    keyframes: {
                        float: {
                            '0%, 100%': { transform: 'translateY(0)' },
                            '50%': { transform: 'translateY(-20px)' },
                        }
                    }
                }
            }
        }
    </script>
    <style>
        .glass {
            background: rgba(255, 255, 255, 0.85);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.3);
        }
        .video-container {
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            border-radius: 2rem;
            overflow: hidden;
            position: relative;
        }
        .gradient-text {
            background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        body {
            background-color: #fffaf5;
            overflow-x: hidden;
        }
        .blob {
            position: absolute;
            width: 500px;
            height: 500px;
            background: radial-gradient(circle, rgba(249, 115, 22, 0.15) 0%, rgba(255, 255, 255, 0) 70%);
            z-index: -1;
            filter: blur(40px);
        }
        
        .nav-link {
            transition: all 0.3s ease;
            position: relative;
        }
        .nav-link::after {
            content: '';
            position: absolute;
            width: 0;
            height: 2px;
            bottom: -4px;
            left: 0;
            background-color: #ea580c;
            transition: width 0.3s ease;
        }
        .nav-link:hover::after, .nav-link.active::after {
            width: 100%;
        }
        .nav-link.active {
            color: #ea580c;
            font-weight: 600;
        }
        
        /* Modal transitions */
        .modal {
            transition: opacity 0.3s ease, visibility 0.3s ease;
        }
        .modal-content {
            transition: transform 0.3s ease;
            transform: scale(0.95);
        }
        .modal.open .modal-content {
            transform: scale(1);
        }
    </style>
</head>
<body class="font-sans text-gray-900 leading-tight relative min-h-screen flex flex-col">

    <!-- Decorative Background Elements -->
    <div class="blob top-[-100px] left-[-100px] animate-pulse-slow"></div>
    <div class="blob bottom-[-100px] right-[-100px] animate-float"></div>

    <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50 glass px-4 py-2 rounded-lg text-brand-600 font-bold shadow-lg">Skip to main content</a>
    
    <header role="banner" class="w-full z-40 sticky top-0 glass border-b border-brand-100">
        <div class="max-w-7xl mx-auto px-6 py-4 flex justify-between items-center">
            <a href="/" aria-label="mitabl home" class="flex items-center gap-2 group">
                <h2 class="text-brand-600 font-extrabold text-2xl tracking-tighter flex items-center justify-center gap-1 group-hover:scale-105 transition-transform duration-300">
                    <span class="bg-brand-600 text-white px-2 py-0.5 rounded-lg shadow-md shadow-brand-500/20">mi</span>tabl
                </h2>
            </a>
            
            <button id="mobile-menu-btn" class="md:hidden text-brand-900 focus:outline-none bg-white p-2 rounded-lg shadow-sm" aria-label="Toggle navigation menu">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
            </button>
            
            <nav id="navbar-menu" class="hidden absolute top-full left-0 w-full md:static md:w-auto md:flex glass md:bg-transparent md:border-none border-b border-brand-100 md:backdrop-filter-none flex-col md:flex-row items-center gap-6 py-6 md:py-0 shadow-lg md:shadow-none transition-all duration-300">
                <ul id="nav-list" class="flex flex-col md:flex-row items-center gap-6 w-full md:w-auto">
                    <li><a class="nav-link text-gray-600 hover:text-brand-600 font-medium" href="/">Home</a></li>
                    <li><a class="nav-link text-gray-600 hover:text-brand-600 font-medium" href="/about">About</a></li>
                    <li><a class="nav-link text-gray-600 hover:text-brand-600 font-medium" href="/faq">FAQ</a></li>
                    <li><a class="nav-link px-6 py-2.5 bg-brand-600 hover:bg-brand-700 text-white rounded-xl font-bold transition-all transform hover:scale-105 shadow-md shadow-brand-500/20 active:scale-95 border-none after:hidden" href="/contact">Contact</a></li>
                </ul>
            </nav>
        </div>
    </header>
    <main id="main-content" tabindex="-1" class="flex-grow w-full max-w-7xl mx-auto px-6 py-12 flex flex-col items-center">
`;

const modal = `
  <div id="myModal" class="modal fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm opacity-0 invisible" role="dialog" aria-modal="true" aria-labelledby="comingSoonTitle">
    <div class="modal-content glass p-8 rounded-[2.5rem] max-w-sm w-full mx-4 shadow-2xl relative text-center flex flex-col items-center">
      <button type="button" class="modal-close absolute top-4 right-4 w-8 h-8 bg-gray-100 hover:bg-gray-200 text-gray-600 rounded-full flex items-center justify-center transition-colors shadow-sm" aria-label="Close coming soon dialog">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
      </button>
      <div class="mb-4 mx-auto w-20 h-20 bg-brand-100 rounded-full flex items-center justify-center">
          <span class="text-3xl">🚀</span>
      </div>
      <h3 id="comingSoonTitle" class="text-xl font-bold text-brand-900 mb-2">Coming Soon...</h3>
      <p class="text-sm text-gray-600">We are preparing something amazing and exciting for you.</p>
    </div>
  </div>
`;

const footer = ({ showStoreBadges }) => `
    </main>
    <footer role="contentinfo" class="w-full relative z-10 glass border-t border-brand-100 mt-20">
      <div class="max-w-7xl mx-auto px-6 py-12 flex flex-col md:flex-row justify-between items-center gap-8">
        
        <div class="flex flex-wrap justify-center md:justify-start gap-x-8 gap-y-4 font-medium text-gray-600">
            <a href="/terms" class="hover:text-brand-600 transition-colors">Terms</a>
            <a href="/privacy-policy" class="hover:text-brand-600 transition-colors">Privacy Policy</a>
            <a href="/contact" class="hover:text-brand-600 transition-colors">Contact</a>
        </div>
        
        <div class="flex items-center justify-center">
            <h2 class="text-gray-400 font-extrabold text-2xl tracking-tighter flex items-center justify-center gap-1 grayscale opacity-70">
                <span class="bg-gray-400 text-white px-2 py-0.5 rounded-lg shadow-sm">mi</span>tabl
            </h2>
        </div>
        
        <div class="flex justify-center md:justify-end gap-4 h-11">
            <style>
               .badge-img { object-fit: contain; width: 100%; height: 100%; border-radius: 0.5rem; }
            </style>
            ${showStoreBadges ? \`
              <button data-target="#myModal" class="modal-trigger h-full rounded-xl overflow-hidden hover:scale-105 transition-transform shadow-sm" aria-label="Open coming soon message for Google Play">
                <img src="/frontend/images/google.png" alt="Get it on Google Play" class="badge-img">
              </button>
              <button data-target="#myModal" class="modal-trigger h-full rounded-xl overflow-hidden hover:scale-105 transition-transform shadow-sm" aria-label="Open coming soon message for App Store">
                <img src="/frontend/images/app.png" alt="Download on the App Store" class="badge-img">
              </button>
            \` : \`
              <a href="https://instagram.com/_mitabl_/" target="_blank" rel="noopener noreferrer" class="text-brand-600 font-bold hover:text-brand-700 transition-colors flex items-center gap-2" aria-label="Visit mitabl Instagram">
                <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true" focusable="false">
                  <path d="M7.75 2h8.5A5.75 5.75 0 0 1 22 7.75v8.5A5.75 5.75 0 0 1 16.25 22h-8.5A5.75 5.75 0 0 1 2 16.25v-8.5A5.75 5.75 0 0 1 7.75 2Zm0 1.75A4 4 0 0 0 3.75 7.75v8.5a4 4 0 0 0 4 4h8.5a4 4 0 0 0 4-4v-8.5a4 4 0 0 0-4-4h-8.5Zm8.9 1.5a1.1 1.1 0 1 1 0 2.2 1.1 1.1 0 0 1 0-2.2ZM12 7a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0 1.75A3.25 3.25 0 1 0 12 15.25 3.25 3.25 0 0 0 12 8.75Z" fill="currentColor"></path>
                </svg>
                Instagram
              </a>
            \`}
        </div>
      </div>
      
      <div class="px-6 py-6 border-t border-gray-200/50">
        <div class="max-w-7xl mx-auto flex flex-col sm:flex-row justify-between items-center gap-4 text-sm text-gray-500">
            <p>&copy; 2026 mitabl All rights reserved.</p>
            <a href="https://instagram.com/_mitabl_/" target="_blank" rel="noopener noreferrer" class="hover:text-brand-600 transition-colors" aria-label="Visit mitabl Instagram">
                <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true" focusable="false">
                  <path d="M7.75 2h8.5A5.75 5.75 0 0 1 22 7.75v8.5A5.75 5.75 0 0 1 16.25 22h-8.5A5.75 5.75 0 0 1 2 16.25v-8.5A5.75 5.75 0 0 1 7.75 2Zm0 1.75A4 4 0 0 0 3.75 7.75v8.5a4 4 0 0 0 4 4h8.5a4 4 0 0 0 4-4v-8.5a4 4 0 0 0-4-4h-8.5Zm8.9 1.5a1.1 1.1 0 1 1 0 2.2 1.1 1.1 0 0 1 0-2.2ZM12 7a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0 1.75A3.25 3.25 0 1 0 12 15.25 3.25 3.25 0 0 0 12 8.75Z" fill="currentColor"></path>
                </svg>
            </a>
        </div>
      </div>
    </footer>

    <script>
        // Custom active link logic
        document.addEventListener("DOMContentLoaded", () => {
            const currentPath = window.location.pathname;
            const currentPathEnd = currentPath.split('/').filter(Boolean).pop() || "";
            
            const navLinks = document.querySelectorAll('#nav-list .nav-link:not(.bg-brand-600)');
            
            navLinks.forEach(link => {
                const linkHref = link.getAttribute('href');
                const linkPathEnd = linkHref.split('/').filter(Boolean).pop() || "";
                
                if ((currentPath === "/" || currentPath.endsWith("/index.html")) && (linkHref === "/" || linkHref.endsWith("/index.html"))) {
                    link.classList.add('active');
                } else if (currentPath !== "/" && !currentPath.endsWith("/index.html") && linkPathEnd === currentPathEnd) {
                    link.classList.add('active');
                }
            });

            // Mobile menu toggle
            const mobileBtn = document.getElementById('mobile-menu-btn');
            const navMenu = document.getElementById('navbar-menu');
            
            if (mobileBtn && navMenu) {
                mobileBtn.addEventListener('click', () => {
                    navMenu.classList.toggle('hidden');
                    navMenu.classList.toggle('flex');
                });
            }

            // Modal logic
            const modal = document.getElementById('myModal');
            const modalTriggers = document.querySelectorAll('.modal-trigger');
            const modalCloseBtns = document.querySelectorAll('.modal-close, .modal');
            const modalContent = document.querySelector('.modal-content');

            if (modal) {
                modalTriggers.forEach(trigger => {
                    trigger.addEventListener('click', (e) => {
                        e.preventDefault();
                        modal.classList.remove('invisible', 'opacity-0');
                        modal.classList.add('open');
                        setTimeout(() => modal.classList.add('opacity-100'), 10);
                    });
                });
                
                modalCloseBtns.forEach(btn => {
                    btn.addEventListener('click', (e) => {
                        if (e.target === modal || btn.classList.contains('modal-close')) {
                            e.preventDefault();
                            modal.classList.remove('opacity-100', 'open');
                            setTimeout(() => modal.classList.add('invisible', 'opacity-0'), 300);
                        }
                    });
                });
                
                // Prevent click inside modal content from closing
                if (modalContent) {
                    modalContent.addEventListener('click', (e) => {
                        e.stopPropagation();
                    });
                }
            }
        });
    </script>
  </body>
</html>
`;

module.exports = { header, footer, modal };
