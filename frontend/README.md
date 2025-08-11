# ALNWOKS Solutions Limited - Corporate Website

A modern, professional website for ALNWOKS Solutions Limited built with cutting-edge web technologies and optimized for performance, accessibility, and user experience.

## 🚀 Features

- **Modern Design**: Clean, professional design with ALNWOKS brand colors and typography
- **Responsive**: Fully responsive design that works on all devices
- **Interactive**: Dynamic product showcase with Alpine.js
- **Animated**: Smooth scroll animations with AOS (Animate On Scroll)
- **Optimized**: Built with performance and SEO in mind
- **Accessible**: WCAG 2.1 AA compliant design
- **Modular**: Component-based architecture for easy maintenance

## 🛠 Technology Stack

- **HTML5**: Semantic markup with proper SEO meta tags
- **Tailwind CSS**: Utility-first CSS framework for rapid development
- **Alpine.js**: Lightweight JavaScript framework for interactivity
- **AOS**: Animate On Scroll library for smooth animations
- **PostCSS**: CSS processing with autoprefixer
- **Webpack**: Module bundler for JavaScript
- **Express.js**: Development server with hot reload
- **Nginx**: Production web server with performance optimizations
- **Docker**: Containerization for consistent deployment

## 📁 Project Structure

```
frontend/
├── src/
│   ├── css/
│   │   └── main.css          # Main stylesheet with Tailwind and custom styles
│   └── js/
│       └── main.js           # Main JavaScript file with Alpine.js components
├── dist/                     # Built assets (generated)
├── assets/                   # Static assets (images, icons, etc.)
├── index.html               # Main website file
├── package.json             # Node.js dependencies and scripts
├── tailwind.config.js       # Tailwind CSS configuration
├── postcss.config.js        # PostCSS configuration
├── webpack.config.js        # Webpack configuration
├── server.js                # Express development server
├── nginx.conf               # Nginx production configuration
├── Dockerfile               # Docker image definition
└── README.md               # This file
```

## 🎨 Design System

### Colors
- **Primary Blue**: #1E3A8A (trust, technology, professionalism)
- **Secondary Green**: #059669 (growth, innovation, success)
- **Accent Orange**: #EA580C (energy, creativity, action)
- **Neutral Gray**: #6B7280 (balance, sophistication, readability)

### Typography
- **Headings**: Inter (modern, readable, professional)
- **Body Text**: Open Sans (readable, friendly)
- **Code/Technical**: Fira Code (technical content)

### Components
- Navigation with mobile-responsive hamburger menu
- Hero section with gradient background and trust indicators
- Interactive product showcase with tabbed interface
- Contact forms with validation
- Animated statistics counters
- Responsive card layouts
- Call-to-action buttons with hover effects

## 🚀 Getting Started

### Prerequisites
- Node.js (v18 or higher)
- Docker (v20.10 or higher)
- Docker Compose (v2.0 or higher)
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd frontend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start development server**
   ```bash
   npm run dev
   ```

4. **Build for production**
   ```bash
   npm run build
   ```

### Available Scripts

- `npm run dev` - Start development server with live reload
- `npm run build` - Build CSS and JavaScript for production
- `npm run build:css` - Build CSS only
- `npm run build:js` - Build JavaScript only
- `npm run watch` - Watch for changes and rebuild automatically
- `npm run lint` - Lint JavaScript files
- `npm run format` - Format code with Prettier
- `npm run audit` - Audit dependencies for security vulnerabilities

## 🐳 Docker Deployment

The frontend can be containerized using Docker for consistent deployment across environments:

```bash
# Build the Docker image
docker build -t alnwoks-frontend .

# Run the container
docker run -p 3001:80 alnwoks-frontend
```

Or using Docker Compose:
```bash
# Start services
docker-compose -f ../docker-compose.frontend.yml up -d

# Stop services
docker-compose -f ../docker-compose.frontend.yml down
```

## 📱 Responsive Design

The website is fully responsive with breakpoints:
- **Mobile**: 320px - 767px
- **Tablet**: 768px - 1023px
- **Desktop**: 1024px - 1439px
- **Large Desktop**: 1440px+

## ♿ Accessibility

- WCAG 2.1 AA compliant
- Keyboard navigation support
- Screen reader compatible
- High contrast color ratios
- Alt text for all images
- Semantic HTML structure

## 🔍 SEO Optimization

- Semantic HTML5 structure
- Meta tags for social sharing (Open Graph, Twitter Cards)
- Structured data (JSON-LD)
- Optimized images with alt text
- Clean URL structure
- Fast loading times
- Mobile-first design

## 🎯 Key Sections

### 1. Hero Section
- Compelling headline with gradient text effect
- Clear value proposition
- Call-to-action buttons
- Trust indicators with key metrics

### 2. About Section
- Company overview and strategic approach
- Key differentiators with icons
- Statistics grid with company metrics

### 3. Solutions Section
- Government and Commercial divisions
- Feature lists with benefits
- Clear calls-to-action

### 4. Products Section
- Interactive product showcase
- Tabbed interface for easy navigation
- Links to individual product websites
- Feature highlights for each product

### 5. Case Studies Section
- Success stories from different sectors
- Quantifiable results and outcomes
- Industry-specific examples

### 6. Partnerships Section
- Partnership opportunities
- Benefits of collaboration
- Partner application process

### 7. Contact Section
- Contact form with validation
- Multiple contact methods
- Office locations and information

## 🔧 Customization

### Adding New Sections
1. Add HTML structure to `index.html`
2. Add corresponding styles to `src/css/main.css`
3. Add JavaScript functionality to `src/js/main.js` if needed

### Modifying Colors
Update the color palette in `tailwind.config.js`:
```javascript
colors: {
  primary: { /* your primary colors */ },
  secondary: { /* your secondary colors */ },
  accent: { /* your accent colors */ }
}
```

### Adding New Components
1. Create component styles in `src/css/main.css`
2. Add Alpine.js data and methods in `src/js/main.js`
3. Use the component in your HTML

## 📊 Performance

- **Lighthouse Score**: 95+ (Performance, Accessibility, Best Practices, SEO)
- **Page Load Time**: <3 seconds on desktop, <4 seconds on mobile
- **Core Web Vitals**: Meets Google's recommended thresholds
- **Image Optimization**: Lazy loading and responsive images
- **CSS/JS Minification**: Optimized for production builds

## 🔒 Security

- Content Security Policy headers
- HTTPS enforcement
- Input validation and sanitization
- XSS protection
- CSRF protection for forms

## 🌐 Browser Support

- Chrome (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Edge (latest 2 versions)
- Mobile browsers (iOS Safari, Android Chrome)

## 📈 Analytics Integration

Ready for integration with:
- Google Analytics 4
- Google Tag Manager
- Facebook Pixel
- LinkedIn Insight Tag
- Custom analytics solutions

## 🚀 Deployment

### Development
For local development, use the unified deployment script:
```bash
# Start development server
../scripts/deploy-frontend.sh dev

# Build assets
../scripts/deploy-frontend.sh build

# Start container
../scripts/deploy-frontend.sh start

# Stop container
../scripts/deploy-frontend.sh stop
```

### Production
For production deployment, use the remote deployment script:
```bash
# Deploy to remote server
../scripts/deploy-frontend.sh deploy
```

### Static Hosting
The website can be deployed to any static hosting service:
- Netlify
- Vercel
- GitHub Pages
- AWS S3 + CloudFront
- Azure Static Web Apps

### Build Process
1. Run `npm run build` to generate production assets
2. Upload the entire frontend directory to your hosting service
3. Configure your domain and SSL certificate

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is proprietary to ALNWOKS Solutions Limited.

## 📞 Support

For technical support or questions about the website:
- Email: tech@alnwoks.com
- Documentation: See `/docs` directory
- Issues: Create an issue in the repository

---

**Built with ❤️ by the ALNWOKS Development Team**