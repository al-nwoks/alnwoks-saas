// ALNWOKS Website Main JavaScript
// Modern, modular JavaScript for enhanced user experience

// Import Alpine.js for reactive components
import Alpine from 'alpinejs';

// Import AOS for scroll animations
import AOS from 'aos';
import 'aos/dist/aos.css';

// Import Swiper for carousels
import { Autoplay, EffectFade, Navigation, Pagination, Swiper } from 'swiper';
import 'swiper/css';
import 'swiper/css/effect-fade';
import 'swiper/css/navigation';
import 'swiper/css/pagination';

// Configure Swiper modules
Swiper.use([Navigation, Pagination, Autoplay, EffectFade]);

// Alpine.js Data Components
document.addEventListener('alpine:init', () => {
  // Navigation Component
  Alpine.data('navigation', () => ({
    isOpen: false,
    activeSection: 'home',
    
    init() {
      this.updateActiveSection();
      window.addEventListener('scroll', () => this.updateActiveSection());
    },
    
    toggleMenu() {
      this.isOpen = !this.isOpen;
    },
    
    closeMenu() {
      this.isOpen = false;
    },
    
    updateActiveSection() {
      const sections = document.querySelectorAll('section[id]');
      const scrollPos = window.scrollY + 100;
      
      sections.forEach(section => {
        const top = section.offsetTop;
        const bottom = top + section.offsetHeight;
        
        if (scrollPos >= top && scrollPos <= bottom) {
          this.activeSection = section.id;
        }
      });
    }
  }));
  
  // Contact Form Component
  Alpine.data('contactForm', () => ({
    formData: {
      name: '',
      email: '',
      company: '',
      phone: '',
      subject: '',
      message: '',
      interest: '',
      budget: ''
    },
    isSubmitting: false,
    isSubmitted: false,
    errors: {},
    
    async submitForm() {
      this.isSubmitting = true;
      this.errors = {};
      
      // Validate form
      if (!this.validateForm()) {
        this.isSubmitting = false;
        return;
      }
      
      try {
        // Simulate API call (replace with actual endpoint)
        await this.sendFormData();
        this.isSubmitted = true;
        this.resetForm();
      } catch (error) {
        console.error('Form submission error:', error);
        this.errors.general = 'There was an error submitting your form. Please try again.';
      } finally {
        this.isSubmitting = false;
      }
    },
    
    validateForm() {
      let isValid = true;
      
      if (!this.formData.name.trim()) {
        this.errors.name = 'Name is required';
        isValid = false;
      }
      
      if (!this.formData.email.trim()) {
        this.errors.email = 'Email is required';
        isValid = false;
      } else if (!this.isValidEmail(this.formData.email)) {
        this.errors.email = 'Please enter a valid email address';
        isValid = false;
      }
      
      if (!this.formData.message.trim()) {
        this.errors.message = 'Message is required';
        isValid = false;
      }
      
      return isValid;
    },
    
    isValidEmail(email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      return emailRegex.test(email);
    },
    
    async sendFormData() {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Here you would typically send to your backend
      console.log('Form data:', this.formData);
      
      // For demo purposes, we'll just log and resolve
      return Promise.resolve();
    },
    
    resetForm() {
      this.formData = {
        name: '',
        email: '',
        company: '',
        phone: '',
        subject: '',
        message: '',
        interest: '',
        budget: ''
      };
    }
  }));
  
  // Newsletter Signup Component
  Alpine.data('newsletter', () => ({
    email: '',
    isSubmitting: false,
    isSubmitted: false,
    error: '',
    
    async subscribe() {
      if (!this.email.trim()) {
        this.error = 'Email is required';
        return;
      }
      
      if (!this.isValidEmail(this.email)) {
        this.error = 'Please enter a valid email address';
        return;
      }
      
      this.isSubmitting = true;
      this.error = '';
      
      try {
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1500));
        this.isSubmitted = true;
        this.email = '';
      } catch (error) {
        this.error = 'Subscription failed. Please try again.';
      } finally {
        this.isSubmitting = false;
      }
    },
    
    isValidEmail(email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      return emailRegex.test(email);
    }
  }));
  
  // Stats Counter Component
  Alpine.data('statsCounter', () => ({
    stats: [
      { value: 0, target: 200, suffix: '%', label: 'Revenue Growth' },
      { value: 0, target: 50, suffix: '+', label: 'Active Partnerships' },
      { value: 0, target: 10, suffix: 'M+', label: 'Pipeline Value' },
      { value: 0, target: 90, suffix: '%', label: 'Customer Retention' }
    ],
    hasAnimated: false,
    
    init() {
      this.observeElement();
    },
    
    observeElement() {
      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting && !this.hasAnimated) {
            this.animateCounters();
            this.hasAnimated = true;
          }
        });
      });
      
      observer.observe(this.$el);
    },
    
    animateCounters() {
      this.stats.forEach((stat, index) => {
        this.animateValue(index, 0, stat.target, 2000);
      });
    },
    
    animateValue(index, start, end, duration) {
      const startTime = performance.now();
      const animate = (currentTime) => {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // Easing function for smooth animation
        const easeOutQuart = 1 - Math.pow(1 - progress, 4);
        const current = Math.floor(start + (end - start) * easeOutQuart);
        
        this.stats[index].value = current;
        
        if (progress < 1) {
          requestAnimationFrame(animate);
        }
      };
      
      requestAnimationFrame(animate);
    }
  }));
  
  // Product Showcase Component
  Alpine.data('productShowcase', () => ({
    activeProduct: 'eazybdc',
    products: {
      eazybdc: {
        name: 'eazyBDC',
        tagline: 'Bureau de Change Management',
        description: 'Streamline your Bureau de Change operations with automated compliance, real-time reporting, and intelligent workflow management.',
        features: ['Automated Compliance', 'Real-time Reporting', 'Customer Management', 'Rate Management'],
        link: 'https://eazybdc.com',
        color: 'from-blue-600 to-yellow-500'
      },
      flowai: {
        name: 'Flow AI',
        tagline: 'Enterprise Conversational AI',
        description: 'Build intelligent chatbots with advanced RAG infrastructure, seamless integrations, and enterprise-grade security.',
        features: ['RAG Infrastructure', 'Developer APIs', 'Enterprise Security', 'Custom Integration'],
        link: 'https://flowai.com',
        color: 'from-blue-600 to-purple-600'
      },
      ottomate: {
        name: 'Ottomate',
        tagline: 'No-Code Workflow Automation',
        description: 'Empower your team to create powerful workflow automations without coding, driving efficiency across your organization.',
        features: ['Visual Designer', 'Pre-built Templates', 'Team Collaboration', 'Analytics Dashboard'],
        link: 'https://ottomate.com',
        color: 'from-green-600 to-blue-600'
      },
      datatloop: {
        name: 'Datatloop',
        tagline: 'Data Orchestration Platform',
        description: 'Revolutionary data synthesis platform that transforms how enterprises discover insights from complex data ecosystems.',
        features: ['Data Synthesis', 'Intelligent Orchestration', 'Enterprise Scale', 'Advanced Analytics'],
        link: 'https://datatloop.com',
        color: 'from-orange-600 to-blue-600'
      }
    },
    
    setActiveProduct(productId) {
      this.activeProduct = productId;
    },
    
    getActiveProduct() {
      return this.products[this.activeProduct];
    }
  }));
// Register Alpine.js components for use in HTML
document.addEventListener('alpine:init', () => {
  Alpine.data('navigation', () => ({
    isOpen: false,
    activeSection: 'home',
    
    init() {
      this.updateActiveSection();
      window.addEventListener('scroll', () => this.updateActiveSection());
    },
    
    toggleMenu() {
      this.isOpen = !this.isOpen;
    },
    
    closeMenu() {
      this.isOpen = false;
    },
    
    updateActiveSection() {
      const sections = document.querySelectorAll('section[id]');
      const scrollPos = window.scrollY + 100;
      
      sections.forEach(section => {
        const top = section.offsetTop;
        const bottom = top + section.offsetHeight;
        
        if (scrollPos >= top && scrollPos <= bottom) {
          this.activeSection = section.id;
        }
      });
    }
  }));

  Alpine.data('productShowcase', () => ({
    activeProduct: 'eazybdc',
    products: {
      eazybdc: {
        name: 'eazyBDC',
        tagline: 'Bureau de Change Management',
        description: 'Streamline your Bureau de Change operations with automated compliance, real-time reporting, and intelligent workflow management.',
        features: ['Automated Compliance', 'Real-time Reporting', 'Customer Management', 'Rate Management'],
        link: 'https://eazybdc.com',
        color: 'from-blue-600 to-yellow-500'
      },
      flowai: {
        name: 'Flow AI',
        tagline: 'Enterprise Conversational AI',
        description: 'Build intelligent chatbots with advanced RAG infrastructure, seamless integrations, and enterprise-grade security.',
        features: ['RAG Infrastructure', 'Developer APIs', 'Enterprise Security', 'Custom Integration'],
        link: 'https://flowai.com',
        color: 'from-blue-600 to-purple-600'
      },
      ottomate: {
        name: 'Ottomate',
        tagline: 'No-Code Workflow Automation',
        description: 'Empower your team to create powerful workflow automations without coding, driving efficiency across your organization.',
        features: ['Visual Designer', 'Pre-built Templates', 'Team Collaboration', 'Analytics Dashboard'],
        link: 'https://ottomate.com',
        color: 'from-green-600 to-blue-600'
      },
      datatloop: {
        name: 'Datatloop',
        tagline: 'Data Orchestration Platform',
        description: 'Revolutionary data synthesis platform that transforms how enterprises discover insights from complex data ecosystems.',
        features: ['Data Synthesis', 'Intelligent Orchestration', 'Enterprise Scale', 'Advanced Analytics'],
        link: 'https://datatloop.com',
        color: 'from-orange-600 to-blue-600'
      }
    },
    
    setActiveProduct(productId) {
      this.activeProduct = productId;
    },
    
    getActiveProduct() {
      return this.products[this.activeProduct];
    }
  }));

  Alpine.data('contactForm', () => ({
    formData: {
      name: '',
      email: '',
      company: '',
      phone: '',
      subject: '',
      message: '',
      interest: '',
      budget: ''
    },
    isSubmitting: false,
    isSubmitted: false,
    errors: {},
    
    async submitForm() {
      this.isSubmitting = true;
      this.errors = {};
      
      // Validate form
      if (!this.validateForm()) {
        this.isSubmitting = false;
        return;
      }
      
      try {
        // Simulate API call (replace with actual endpoint)
        await this.sendFormData();
        this.isSubmitted = true;
        this.resetForm();
      } catch (error) {
        console.error('Form submission error:', error);
        this.errors.general = 'There was an error submitting your form. Please try again.';
      } finally {
        this.isSubmitting = false;
      }
    },
    
    validateForm() {
      let isValid = true;
      
      if (!this.formData.name.trim()) {
        this.errors.name = 'Name is required';
        isValid = false;
      }
      
      if (!this.formData.email.trim()) {
        this.errors.email = 'Email is required';
        isValid = false;
      } else if (!this.isValidEmail(this.formData.email)) {
        this.errors.email = 'Please enter a valid email address';
        isValid = false;
      }
      
      if (!this.formData.message.trim()) {
        this.errors.message = 'Message is required';
        isValid = false;
      }
      
      return isValid;
    },
    
    isValidEmail(email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      return emailRegex.test(email);
    },
    
    async sendFormData() {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Here you would typically send to your backend
      console.log('Form data:', this.formData);
      
      // For demo purposes, we'll just log and resolve
      return Promise.resolve();
    },
    
    resetForm() {
      this.formData = {
        name: '',
        email: '',
        company: '',
        phone: '',
        subject: '',
        message: '',
        interest: '',
        budget: ''
      };
    }
  }));
});
});

// Initialize Alpine.js
window.Alpine = Alpine;
Alpine.start();

// Initialize AOS (Animate On Scroll)
document.addEventListener('DOMContentLoaded', () => {
  AOS.init({
    duration: 800,
    easing: 'ease-out-cubic',
    once: true,
    offset: 100
  });
});

// Utility Functions
class WebsiteUtils {
  // Smooth scroll to element
  static scrollToElement(elementId, offset = 80) {
    const element = document.getElementById(elementId);
    if (element) {
      const elementPosition = element.offsetTop - offset;
      window.scrollTo({
        top: elementPosition,
        behavior: 'smooth'
      });
    }
  }
  
  // Lazy load images
  static initLazyLoading() {
    const images = document.querySelectorAll('img[data-src]');
    const imageObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target;
          img.src = img.dataset.src;
          img.classList.remove('lazy');
          imageObserver.unobserve(img);
        }
      });
    
    images.forEach(img => imageObserver.observe(img));
  }
  
  // Initialize testimonial carousel
  static initTestimonialCarousel() {
    const testimonialSwiper = new Swiper('.testimonial-carousel', {
      slidesPerView: 1,
      spaceBetween: 30,
      autoplay: {
        delay: 5000,
        disableOnInteraction: false,
      },
      pagination: {
        el: '.swiper-pagination',
        clickable: true,
      },
      navigation: {
        nextEl: '.swiper-button-next',
        prevEl: '.swiper-button-prev',
      },
      breakpoints: {
        768: {
          slidesPerView: 2,
        },
        1024: {
          slidesPerView: 3,
        },
      },
    });
  }
  
  // Initialize hero carousel
  static initHeroCarousel() {
    const heroSwiper = new Swiper('.hero-carousel', {
      slidesPerView: 1,
      effect: 'fade',
      autoplay: {
        delay: 7000,
        disableOnInteraction: false,
      },
      pagination: {
        el: '.hero-pagination',
        clickable: true,
      },
      navigation: {
        nextEl: '.hero-button-next',
        prevEl: '.hero-button-prev',
      },
    });
  }
  
  // Handle form submissions with analytics
  static trackFormSubmission(formType, formData) {
    // Google Analytics 4 event tracking
    if (typeof gtag !== 'undefined') {
      gtag('event', 'form_submit', {
        form_type: formType,
        engagement_time_msec: Date.now()
      });
    }
    
    // Additional analytics tracking can be added here
    console.log(`Form submitted: ${formType}`, formData);
  }
  
  // Performance monitoring
  static initPerformanceMonitoring() {
    // Monitor Core Web Vitals
    if ('web-vital' in window) {
      import('web-vitals').then(({ getCLS, getFID, getFCP, getLCP, getTTFB }) => {
        getCLS(console.log);
        getFID(console.log);
        getFCP(console.log);
        getLCP(console.log);
        getTTFB(console.log);
      });
    }
  }
  
  // Initialize all website features
  static init() {
    this.initLazyLoading();
    this.initTestimonialCarousel();
    this.initHeroCarousel();
    this.initPerformanceMonitoring();
    
    // Add smooth scrolling to all anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const targetId = this.getAttribute('href').substring(1);
        WebsiteUtils.scrollToElement(targetId);
      });
    });
    
    // Add loading states to buttons
    document.querySelectorAll('button[type="submit"]').forEach(button => {
      button.addEventListener('click', function() {
        if (this.form && this.form.checkValidity()) {
          this.classList.add('loading');
          setTimeout(() => {
            this.classList.remove('loading');
          }, 2000);
        }
      });
    });
  }
}

// Initialize website features when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  WebsiteUtils.init();
});

// Export for global access
window.WebsiteUtils = WebsiteUtils;

// Service Worker Registration removed for now to avoid 404 (no sw.js yet)
// Consider adding Workbox-based SW in a future iteration.