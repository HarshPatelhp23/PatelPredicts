import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "playersContainer", 
    "playerCard", 
    "playerDetails", 
    "quickStats",
    "cricketBall"
  ]

  connect() {
    this.initTheme()
    this.initAnimations()
    this.calculateTopPerformers()
  }

  initTheme() {
    const themeToggle = document.getElementById('themeToggle')
    const themeIcon = document.getElementById('themeIcon')
    const themeText = document.getElementById('themeText')
    const html = document.documentElement
    
    const currentTheme = localStorage.getItem('theme') || 'light'
    html.setAttribute('data-theme', currentTheme)
    this.updateThemeButton(currentTheme, themeIcon, themeText)
    
    themeToggle.addEventListener('click', () => {
      const currentTheme = html.getAttribute('data-theme')
      const newTheme = currentTheme === 'light' ? 'dark' : 'light'
      
      html.setAttribute('data-theme', newTheme)
      localStorage.setItem('theme', newTheme)
      this.updateThemeButton(newTheme, themeIcon, themeText)
    })
  }

  updateThemeButton(theme, icon, text) {
    if (theme === 'dark') {
      icon.className = 'fas fa-sun'
      text.textContent = 'Light'
    } else {
      icon.className = 'fas fa-moon'
      text.textContent = 'Dark'
    }
  }

  initAnimations() {
    // Animate cricket balls
    this.animateCricketBalls()
    
    // Add scroll animations
    this.setupScrollAnimations()
  }

  animateCricketBalls() {
    const balls = this.cricketBallTargets
    balls.forEach((ball, index) => {
      ball.style.animationDelay = `${index * 2}s`
      ball.style.left = `${Math.random() * 90}%`
      ball.style.top = `${Math.random() * 90}%`
    })
  }

  setupScrollAnimations() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('fade-in')
        }
      })
    }, { threshold: 0.1 })

    this.playerCardTargets.forEach(card => {
      observer.observe(card)
    })
  }

  searchPlayers(event) {
    const query = event.target.value.toLowerCase()
    
    this.playerCardTargets.forEach(card => {
      const playerName = card.getAttribute('data-player-name')
      if (playerName.includes(query)) {
        card.style.display = 'block'
        card.classList.add('fade-in')
      } else {
        card.style.display = 'none'
      }
    })
  }

  togglePlayerDetails(event) {
    const button = event.currentTarget
    const card = button.closest('.player-card-modern')
    const details = card.querySelector('.player-details-content')
    const icon = button.querySelector('i')
    
    details.classList.toggle('hidden')
    icon.classList.toggle('fa-chevron-down')
    icon.classList.toggle('fa-chevron-up')
    
    if (!details.classList.contains('hidden')) {
      details.style.maxHeight = details.scrollHeight + 'px'
    } else {
      details.style.maxHeight = '0'
    }
  }

  switchSeason(event) {
    const button = event.currentTarget
    const season = button.getAttribute('data-season')
    const card = button.closest('.player-card-modern')
    const statsContainer = card.querySelector('.stats-content')
    
    // Update active tab
    card.querySelectorAll('.season-tab').forEach(tab => {
      tab.classList.remove('active')
    })
    button.classList.add('active')
    
    // Show corresponding season stats
    statsContainer.querySelectorAll('.season-stats').forEach(stats => {
      stats.classList.remove('active')
      if (stats.getAttribute('data-season') === season) {
        stats.classList.add('active')
      }
    })
  }

  toggleView(event) {
    const button = event.currentTarget
    const view = button.getAttribute('data-view')
    const container = this.playersContainerTarget
    
    // Update active button
    this.element.querySelectorAll('.view-toggle-btn').forEach(btn => {
      btn.classList.remove('active')
    })
    button.classList.add('active')
    
    // Switch view
    if (view === 'list') {
      container.classList.add('list-view')
    } else {
      container.classList.remove('list-view')
    }
  }

  calculateTopPerformers() {
    let topPerformerCount = 0
    
    this.playerCardTargets.forEach(card => {
      const rating = parseFloat(card.querySelector('.player-rating-badge').textContent)
      if (rating >= 8) {
        topPerformerCount++
        
        // Add premium badge animation
        const badge = card.querySelector('.player-rating-badge')
        badge.style.animation = 'pulse 2s infinite'
      }
    })
    
    document.getElementById('topPerformerCount').textContent = topPerformerCount
  }

  scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}
