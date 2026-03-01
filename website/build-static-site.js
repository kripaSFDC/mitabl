const fs = require('fs');
const path = require('path');
const { header, footer, modal } = require('./src/templates');

const pages = [
  { slug: 'index', title: 'Mitabl', showModal: true, showStoreBadges: true },
  { slug: 'about', title: 'About mitabl', showModal: true, showStoreBadges: true },
  { slug: 'faq', title: 'FAQ | mitabl', showModal: true, showStoreBadges: true },
  { slug: 'contact', title: 'Contact mitabl', showModal: false, showStoreBadges: false },
  { slug: 'privacy-policy', title: 'Privacy Policy | mitabl', showModal: false, showStoreBadges: false },
  { slug: 'terms', title: 'Terms | mitabl', showModal: false, showStoreBadges: false },
];

for (const page of pages) {
  const pageContentPath = path.join(__dirname, 'src', 'pages', `${page.slug}.html`);
  const outputPath = path.join(__dirname, 'public', `${page.slug}.html`);
  const pageContent = fs.readFileSync(pageContentPath, 'utf8').trim();

  const output = `${header({ pageTitle: page.title })}${pageContent}\n${page.showModal ? modal : ''}${footer({ showStoreBadges: page.showStoreBadges })}`;

  fs.writeFileSync(outputPath, output);
}

console.log(`Built ${pages.length} pages into website/public`);
