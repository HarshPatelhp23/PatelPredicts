import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  
  connect() {
    console.log('Countdown timer controller connected');
    this.startTimer();
  }
  
  startTimer() {
    const updateCountdown = () => {
      const now = new Date();
      
      // Create target time for today at 11:00 PM (23:00)
      const targetTime = new Date();
      targetTime.setHours(23, 0, 0, 0);
      
      // If current time is past 11 PM today, set target to tomorrow 11 PM
      if (now >= targetTime) {
        targetTime.setDate(targetTime.getDate() + 1);
      }
      
      const diff = targetTime - now;
      
      // Format time
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);
      
      if (this.hasDisplayTarget) {
        this.displayTarget.textContent = 
          `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
      }
    };
    
    updateCountdown();
    this.timerInterval = setInterval(updateCountdown, 1000);
  }
  
  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
    }
  }
}