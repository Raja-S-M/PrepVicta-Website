// Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(a => {
      a.addEventListener('click', e => {
        const href = a.getAttribute('href');
        if (href.length > 1) {
          e.preventDefault();
          document.querySelector(href)?.scrollIntoView({ behavior: 'smooth' });
        }
      });
    });

    // Active tab highlighting on scroll
    const tabs = document.querySelectorAll('.nav-tab[data-section]');
    const sections = Array.from(tabs).map(t => document.getElementById(t.dataset.section)).filter(Boolean);

    function setActiveTab(id) {
      tabs.forEach(t => {
        t.classList.toggle('active', t.dataset.section === id);
      });
      // Scroll active tab into view within the tab bar
      const active = document.querySelector(`.nav-tab[data-section="${id}"]`);
      if (active) active.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    }

    const navHeight = 100;
    window.addEventListener('scroll', () => {
      const scrollY = window.scrollY + navHeight + 40;
      let current = sections[0]?.id || 'hero';
      sections.forEach(sec => {
        if (sec.offsetTop <= scrollY) current = sec.id;
      });
      setActiveTab(current);
    }, { passive: true });

    // Animate stat numbers on scroll
    function animateNum(el, target, suffix = '') {
      let start = 0;
      const step = target / 60;
      const timer = setInterval(() => {
        start = Math.min(start + step, target);
        el.textContent = Math.floor(start) + suffix;
        if (start >= target) clearInterval(timer);
      }, 16);
    }

    const statsObserver = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          const cells = document.querySelectorAll('.stat-num');
          cells[0] && animateNum(cells[0], 360, '+');
          cells[1] && animateNum(cells[1], 3, '×');
          cells[2] && animateNum(cells[2], 180, '');
          statsObserver.disconnect();
        }
      });
    }, { threshold: 0.5 });

    const statsSection = document.getElementById('stats');
    if (statsSection) statsObserver.observe(statsSection);

    // Fade-in on scroll
    const fadeEls = document.querySelectorAll('.problem-card, .feature-card, .how-step, .outcome-card, .who-card');
    const fadeObserver = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          e.target.style.opacity = '1';
          e.target.style.transform = 'translateY(0)';
          fadeObserver.unobserve(e.target);
        }
      });
    }, { threshold: 0.1 });

    fadeEls.forEach(el => {
      el.style.opacity = '0';
      el.style.transform = 'translateY(16px)';
      el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
      fadeObserver.observe(el);
    });
  


    function openModal() {
      document.getElementById('earlyAccessModal').classList.add('open');
    }
    function closeModal() {
      document.getElementById('earlyAccessModal').classList.remove('open');
    }
    // Close modal when clicking outside of the content
    document.getElementById('earlyAccessModal').addEventListener('click', function (e) {
      if (e.target === this) {
        closeModal();
      }
    });

    // Handle form submission via AJAX to prevent redirect
    document.getElementById('earlyAccessForm').addEventListener('submit', function (e) {
      e.preventDefault(); // Stop standard form submission

      var btn = document.getElementById('submitBtn');
      var originalText = btn.innerText;
      btn.innerText = 'Submitting...';
      btn.disabled = true;

      var formData = new FormData(this);

      fetch('https://formspree.io/f/xzdojqra', {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'application/json'
        }
      })
        .then(response => {
          if (response.ok) {
            return response.json().catch(() => ({}));
          }
          throw new Error('Form submission failed');
        })
        .then(data => {
          btn.innerText = 'Success!';
          btn.style.backgroundColor = '#0E9E7E'; // Teal color
          btn.style.color = '#fff';

          // Close modal and reset form after 2 seconds
          setTimeout(function () {
            closeModal();
            document.getElementById('earlyAccessForm').reset();
            btn.innerText = originalText;
            btn.disabled = false;
            btn.style.backgroundColor = '';
            btn.style.color = '';
          }, 2000);
        })
        .catch(error => {
          console.error('Error:', error);
          btn.innerText = 'Error. Try Again.';
          btn.disabled = false;
          setTimeout(function () {
            btn.innerText = originalText;
          }, 3000);
        });
    });
