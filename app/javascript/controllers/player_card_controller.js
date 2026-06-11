import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replacementBanner"]
  static values  = { isReplacement: Boolean }

  connect() {
    if (this.isReplacementValue && this.hasReplacementBannerTarget) {
      // Trigger the slide-down animation after a short stagger
      // so cards animate in as user scrolls
      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              // Stagger based on card position on screen
              const delay = Math.min(entry.boundingClientRect.top * 0.3, 300)
              setTimeout(() => {
                this.replacementBannerTarget.classList.add("banner-animate-in")
                // Haptic feedback on mobile
                if ("vibrate" in navigator) navigator.vibrate([10, 50, 10])
              }, delay)
              observer.disconnect()
            }
          })
        },
        { threshold: 0.3 }
      )
      observer.observe(this.element)
    }
  }
}
