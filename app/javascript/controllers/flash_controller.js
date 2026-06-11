import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-remove after 5 seconds
    setTimeout(() => {
      this.element.style.opacity = "0"
      setTimeout(() => this.element.remove(), 300)
    }, 5000)
  }

  close() {
    this.element.remove()
  }
}

