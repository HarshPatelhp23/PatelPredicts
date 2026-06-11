// app/javascript/controllers/auction_stats_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auction-stats"
export default class extends Controller {
  static targets = [
    "themeIcon",
    "themeText", 
    "searchInput",
    "playerCard",
    "playerGrid"
  ]

  connect() {
    this.initializeTheme()
    this.animateCardsOnLoad()
    this.initializeCricketAnimations()
  }

  // Theme Management
  initializeTheme() {
    const savedTheme = localStorage.getItem('spl-theme') || 'light'
    document.documentElement.setAttribute('data-theme', savedTheme)
    this.updateThemeUI(savedTheme)
  }

  toggleTheme(event) {
    event.preventDefault()
    const currentTheme = document.documentElement.getAttribute('data-theme')
    const newTheme = currentTheme === 'light' ? 'dark' : 'light'
    
    // Add transition class
    document.body.style.transition = 'background-color 0.3s ease'
    
    document.documentElement.setAttribute('data-theme', newTheme)
    localStorage.setItem('spl-theme', newTheme)
    this.updateThemeUI(newTheme)
    
    // Animate theme icon
    this.animateThemeToggle()
  }

  updateThemeUI(theme) {
    if (this.hasThemeIconTarget && this.hasThemeTextTarget) {
      if (theme === 'dark') {
        this.themeIconTarget.className = 'fas fa-sun'
        this.themeTextTarget.textContent = 'Light'
      } else {
        this.themeIconTarget.className = 'fas fa-moon'
        this.themeTextTarget.textContent = 'Dark'
      }
    }
  }

  animateThemeToggle() {
    const button = this.themeIconTarget.closest('.theme-toggle')
    button.style.transform = 'scale(1.2) rotate(180deg)'
    setTimeout(() => {
      button.style.transform = 'scale(1) rotate(0deg)'
    }, 300)
  }

  // Search Functionality
  filterPlayers(event) {
    const query = event.target.value.toLowerCase().trim()
    
    this.playerCardTargets.forEach(card => {
      const playerName = card.dataset.playerName
      const matches = playerName.includes(query)
      
      if (matches) {
        card.style.display = 'block'
        card.style.animation = 'fadeIn 0.3s ease'
      } else {
        card.style.opacity = '0'
        setTimeout(() => {
          card.style.display = 'none'
        }, 300)
      }
    })

    // Add empty state if no results
    this.handleEmptyState(query)
  }

  handleEmptyState(query) {
    const visibleCards = this.playerCardTargets.filter(card => 
      card.style.display !== 'none'
    )

    const existingEmptyState = this.playerGridTarget.querySelector('.empty-state')
    
    if (visibleCards.length === 0 && query.length > 0) {
      if (!existingEmptyState) {
        const emptyState = this.createEmptyState(query)
        this.playerGridTarget.appendChild(emptyState)
      }
    } else if (existingEmptyState) {
      existingEmptyState.remove()
    }
  }

  createEmptyState(query) {
    const div = document.createElement('div')
    div.className = 'empty-state'
    div.innerHTML = `
      <div style="text-align: center; padding: 3rem; grid-column: 1 / -1;">
        <i class="fas fa-search" style="font-size: 3rem; color: var(--text-secondary); margin-bottom: 1rem;"></i>
        <h3 style="color: var(--text-primary); margin-bottom: 0.5rem;">No players found</h3>
        <p style="color: var(--text-secondary);">No results for "${query}"</p>
      </div>
    `
    return div
  }

  // Season Tab Switching
  switchSeason(event) {
    event.preventDefault()
    const button = event.currentTarget
    const season = button.dataset.season
    const playerId = button.dataset.playerId
    
    // Get all tabs and contents for this player
    const card = button.closest('.player-card')
    const tabs = card.querySelectorAll('.season-tab')
    const contents = card.querySelectorAll('.stats-content')
    
    // Remove active from all tabs
    tabs.forEach(tab => tab.classList.remove('active'))
    
    // Add active to clicked tab
    button.classList.add('active')
    
    // Hide all content and show selected
    contents.forEach(content => {
      if (content.dataset.seasonContent === season && 
          content.dataset.playerId === playerId) {
        content.style.display = 'block'
        this.animateStatsReveal(content)
      } else if (content.dataset.playerId === playerId) {
        content.style.display = 'none'
      }
    })

    // Add ripple effect
    this.createRipple(button, event)
  }

  animateStatsReveal(content) {
    const statItems = content.querySelectorAll('.stat-item, .key-stat')
    
    statItems.forEach((item, index) => {
      item.style.opacity = '0'
      item.style.transform = 'translateY(10px)'
      
      setTimeout(() => {
        item.style.transition = 'all 0.3s ease'
        item.style.opacity = '1'
        item.style.transform = 'translateY(0)'
      }, index * 30)
    })

    // Animate rating bar
    const ratingFill = content.querySelector('.rating-fill')
    if (ratingFill) {
      const width = ratingFill.style.width
      ratingFill.style.width = '0%'
      setTimeout(() => {
        ratingFill.style.width = width
      }, 300)
    }
  }

  createRipple(button, event) {
    const ripple = document.createElement('span')
    const rect = button.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height)
    const x = event.clientX - rect.left - size / 2
    const y = event.clientY - rect.top - size / 2
    
    ripple.style.cssText = `
      position: absolute;
      width: ${size}px;
      height: ${size}px;
      border-radius: 50%;
      background: rgba(255,255,255,0.3);
      top: ${y}px;
      left: ${x}px;
      transform: scale(0);
      pointer-events: none;
    `
    
    button.style.position = 'relative'
    button.style.overflow = 'hidden'
    button.appendChild(ripple)
    
    ripple.animate([
      { transform: 'scale(0)', opacity: 1 },
      { transform: 'scale(2)', opacity: 0 }
    ], {
      duration: 600,
      easing: 'ease-out'
    }).onfinish = () => ripple.remove()
  }

  // Card Animations on Load
  animateCardsOnLoad() {
    this.playerCardTargets.forEach((card, index) => {
      card.style.opacity = '0'
      card.style.transform = 'translateY(30px)'
      
      setTimeout(() => {
        card.style.transition = 'all 0.5s ease'
        card.style.opacity = '1'
        card.style.transform = 'translateY(0)'
      }, index * 100)
    })
  }

  // Cricket Ball Animations
  initializeCricketAnimations() {
    const cricketBg = document.querySelector('.cricket-bg')
    if (!cricketBg) return

    // Add random cricket balls
    for (let i = 0; i < 5; i++) {
      setTimeout(() => {
        this.createFloatingBall(cricketBg)
      }, i * 2000)
    }
  }

  createFloatingBall(container) {
    const ball = document.createElement('div')
    ball.className = 'cricket-ball'
    ball.style.left = `${Math.random() * 90}%`
    ball.style.top = `${Math.random() * 90}%`
    ball.style.animationDelay = `${Math.random() * 2}s`
    ball.style.animationDuration = `${3 + Math.random() * 2}s`
    
    container.appendChild(ball)
    
    // Remove after animation
    setTimeout(() => {
      ball.remove()
    }, 8000)
  }

  // Utility: Smooth Scroll
  smoothScrollTo(element) {
    element.scrollIntoView({ 
      behavior: 'smooth', 
      block: 'start' 
    })
  }

  // Performance Badge Animation on Hover
  animateBadge(event) {
    const badge = event.currentTarget
    badge.style.transform = 'scale(1.1) rotate(5deg)'
    
    setTimeout(() => {
      badge.style.transform = 'scale(1) rotate(0deg)'
    }, 300)
  }

  // Cleanup
  disconnect() {
    // Clean up any intervals or listeners if needed
  }
}

// Add CSS animation keyframes dynamically
if (typeof document !== 'undefined') {
  const style = document.createElement('style')
  style.textContent = `
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    @keyframes slideIn {
      from { transform: translateX(-100%); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }
    
    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.05); }
    }
  `
  document.head.appendChild(style)
}
