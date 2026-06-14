// Add this to your loader.js

function injectLoaderCSS() {
  const style = document.createElement('style');
  style.textContent = `
    .loader-container {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: linear-gradient(135deg, #00b4db 0%, #0083b0 100%);
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      z-index: 9999;
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.3s ease;
    }

    .loader-container.active {
      opacity: 1;
      visibility: visible;
    }

    .loader-content {
      text-align: center;
      color: white;
      max-width: 90%;
    }

    .loader-title {
      font-size: 22px;
      font-weight: 600;
      margin-bottom: 10px;
      animation: fadeInUp 0.8s ease forwards;
      opacity: 0;
      transform: translateY(20px);
      animation-delay: 0.5s;
    }

    .loader-subtitle {
      font-size: 16px;
      opacity: 0.9;
      margin-bottom: 30px;
      animation: fadeInUp 0.8s ease forwards;
      opacity: 0;
      transform: translateY(20px);
      animation-delay: 0.7s;
    }

    /* Cricket stadium animation */
    .cricket-loader {
      position: relative;
      width: 200px;
      height: 200px;
      margin-bottom: 30px;
      perspective: 1200px;
    }

    .stadium-3d {
      position: absolute;
      width: 100%;
      height: 100%;
      transform-style: preserve-3d;
      animation: rotate3d 8s infinite linear;
    }

    .pitch-circle {
      position: absolute;
      width: 120px;
      height: 120px;
      background: radial-gradient(ellipse at center, rgba(222, 184, 135, 0.6) 0%, rgba(0, 131, 176, 0.2) 80%);
      border-radius: 50%;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      border: 3px solid rgba(255, 255, 255, 0.2);
      overflow: hidden;
    }

    .pitch-lines {
      position: absolute;
      width: 80%;
      height: 100%;
      left: 10%;
      top: 0;
    }

    .pitch-line {
      position: absolute;
      width: 100%;
      height: 3px;
      background: rgba(255, 255, 255, 0.3);
      left: 0;
    }

    .pitch-line:nth-child(1) { top: 30%; }
    .pitch-line:nth-child(2) { top: 70%; }

    .ball-orbit {
      position: absolute;
      width: 180px;
      height: 180px;
      border: 1px dashed rgba(255, 255, 255, 0.3);
      border-radius: 50%;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      animation: rotate 4s infinite linear;
    }

    .cricket-ball {
      position: absolute;
      width: 20px;
      height: 20px;
      background: white;
      border-radius: 50%;
      top: -10px;
      left: 50%;
      transform: translateX(-50%);
      box-shadow: 0 0 15px rgba(255, 255, 255, 0.8);
    }

    .cricket-ball::after {
      content: '';
      position: absolute;
      width: 20px;
      height: 20px;
      background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none" stroke="red" stroke-width="2"><path d="M20,50 Q50,20 80,50 Q50,80 20,50 Z" /></svg>');
      background-size: cover;
      opacity: 0.7;
    }

    .wickets {
      position: absolute;
      width: 40px;
      height: 40px;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
    }

    .stump {
      position: absolute;
      width: 4px;
      height: 30px;
      background: white;
      bottom: 0;
      border-radius: 2px;
    }

    .stump:nth-child(1) { left: 0; }
    .stump:nth-child(2) { left: 18px; }
    .stump:nth-child(3) { left: 36px; }

    .bail {
      position: absolute;
      width: 40px;
      height: 3px;
      background: white;
      border-radius: 1px;
      top: 0;
    }

    .bat {
      position: absolute;
      width: 8px;
      height: 50px;
      background: #ffaa00;
      border-radius: 4px 4px 0 0;
      bottom: 70px;
      left: 90px;
      transform-origin: bottom center;
      animation: batSwing 2s infinite ease-in-out;
    }

    .bat::after {
      content: '';
      position: absolute;
      width: 18px;
      height: 15px;
      background: #eeeeee;
      border-radius: 4px;
      bottom: -2px;
      left: -5px;
    }

    .loader-progress {
      width: 250px;
      height: 6px;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 3px;
      margin-top: 10px;
      overflow: hidden;
      position: relative;
    }

    .progress-bar {
      position: absolute;
      top: 0;
      left: 0;
      height: 100%;
      width: 0%;
      background: white;
      border-radius: 3px;
      animation: progress 3s ease-in-out forwards;
    }

    .cricket-elements {
      position: absolute;
      width: 100%;
      height: 100%;
      top: 0;
      left: 0;
    }

    .flying-ball {
      position: absolute;
      width: 15px;
      height: 15px;
      background: white;
      border-radius: 50%;
      box-shadow: 0 0 15px rgba(255, 255, 255, 0.8);
      opacity: 0;
      animation: flyingBall 3s infinite;
    }

    .flying-ball:nth-child(1) {
      top: 30%;
      left: 10%;
      animation-delay: 0.5s;
    }

    .flying-ball:nth-child(2) {
      top: 60%;
      left: 20%;
      animation-delay: 1.2s;
    }

    .flying-ball:nth-child(3) {
      top: 20%;
      left: 70%;
      animation-delay: 1.8s;
    }

    .loader-stats {
      display: flex;
      justify-content: center;
      gap: 20px;
      margin-top: 20px;
      opacity: 0;
      animation: fadeInUp 0.8s ease forwards;
      animation-delay: 0.9s;
    }

    .stat-item {
      text-align: center;
      background: rgba(255, 255, 255, 0.1);
      padding: 8px 15px;
      border-radius: 10px;
      min-width: 80px;
    }

    .stat-value {
      font-size: 20px;
      font-weight: 600;
    }

    .stat-label {
      font-size: 12px;
      opacity: 0.8;
    }

    .pulsing-dot {
      width: 10px;
      height: 10px;
      background: white;
      border-radius: 50%;
      display: inline-block;
      margin-left: 5px;
      animation: pulse 1.5s infinite;
    }

    .pulsing-dot:nth-child(2) {
      animation-delay: 0.2s;
    }

    .pulsing-dot:nth-child(3) {
      animation-delay: 0.4s;
    }

    @keyframes pulse {
      0% { transform: scale(0.8); opacity: 0.5; }
      50% { transform: scale(1.2); opacity: 1; }
      100% { transform: scale(0.8); opacity: 0.5; }
    }

    @keyframes rotate {
      0% { transform: translate(-50%, -50%) rotate(0deg); }
      100% { transform: translate(-50%, -50%) rotate(360deg); }
    }

    @keyframes rotate3d {
      0% { transform: rotateY(0deg); }
      100% { transform: rotateY(360deg); }
    }

    @keyframes batSwing {
      0%, 100% { transform: rotate(-30deg); }
      50% { transform: rotate(30deg); }
    }

    @keyframes flyingBall {
      0% { 
        transform: translate(0, 0) scale(0.5); 
        opacity: 0;
      }
      20% { 
        opacity: 1; 
      }
      80% {
        opacity: 1;
      }
      100% { 
        transform: translate(80px, -40px) scale(1); 
        opacity: 0;
      }
    }

    @keyframes progress {
      0% { width: 0%; }
      20% { width: 20%; }
      50% { width: 50%; }
      70% { width: 70%; }
      100% { width: 100%; }
    }

    @keyframes fadeInUp {
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    @keyframes bounce {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-15px); }
    }

    .cricket-logo {
      width: 60px;
      height: 60px;
      background: linear-gradient(135deg, #ff9a44 0%, #fc6076 100%);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
      animation: bounce 2s infinite ease-in-out;
      box-shadow: 0 5px 15px rgba(252, 96, 118, 0.4);
    }

    .logo-icon {
      font-size: 28px;
      color: white;
    }

    @media (max-width: 480px) {
      .cricket-loader {
        transform: scale(0.8);
      }
      
      .loader-title {
        font-size: 18px;
      }
      
      .loader-subtitle {
        font-size: 14px;
      }
      
      .loader-stats {
        flex-wrap: wrap;
      }
    }
  `;
  document.head.appendChild(style);
}

function initializeLoader() {
  injectLoaderCSS();
  const loader = document.getElementById('cricketLoader');
  if (!loader) {
    console.error('Loader element not found!');
    return;
  }

  const percentElement = document.getElementById('loadingPercent');
  const timeElement = document.getElementById('timeRemaining');
  const progressBar = document.querySelector('.progress-bar');

  if (!percentElement || !timeElement || !progressBar) {
    console.error('Required elements not found!');
    return;
  }

  const minimumDisplayTime = 6000; // 6 seconds
  let loaderStartTime = null;
  let progressInterval = null;
  let timeInterval = null;
  let isLoaderActive = false;

  // Function to show the loader
  function showLoader() {
    document.body.classList.add('turbo-loading');
    loaderStartTime = Date.now();
    loader.classList.add('active');
    isLoaderActive = true;
    startLoadingAnimation();
  }

  // Function to hide the loader
  function hideLoader() {
    const elapsedTime = Date.now() - loaderStartTime;
    const remainingTime = minimumDisplayTime - elapsedTime;

    if (remainingTime > 0) {
      // Complete the progress animation smoothly
      const currentProgress = parseFloat(progressBar.style.width) || 0;
      const remainingProgress = 100 - currentProgress;
      const timePerPercent = remainingTime / remainingProgress;
      
      clearInterval(progressInterval);
      progressInterval = setInterval(() => {
        const currentWidth = parseFloat(progressBar.style.width) || 0;
        if (currentWidth < 100) {
          const newWidth = Math.min(currentWidth + 1, 100);
          percentElement.textContent = Math.round(newWidth) + '%';
          progressBar.style.width = newWidth + '%';
          
          // Sync time remaining with percentage
          const percentRemaining = 100 - newWidth;
          const secondsRemaining = Math.ceil((percentRemaining / 100) * (remainingTime / 1000));
          timeElement.textContent = secondsRemaining + 's';
        } else {
          clearInterval(progressInterval);
        }
      }, timePerPercent);
      
      setTimeout(() => {
        loader.classList.remove('active');
        isLoaderActive = false;
        clearInterval(progressInterval);
        clearInterval(timeInterval);
      }, remainingTime);
    } else {
      // If we've already exceeded minimum time, just finish progress and hide
      percentElement.textContent = '100%';
      progressBar.style.width = '100%';
      timeElement.textContent = '0s';
      
      loader.classList.remove('active');
      isLoaderActive = false;
      clearInterval(progressInterval);
      clearInterval(timeInterval);
    }
  }

  // Force hide loader (for back button)
  function forceHideLoader() {
     document.body.classList.remove('turbo-loading');
    if (isLoaderActive) {
      // Set to 100% before hiding
      percentElement.textContent = '100%';
      progressBar.style.width = '100%';
      timeElement.textContent = '0s';
      
      loader.classList.remove('active');
      isLoaderActive = false;
      clearInterval(progressInterval);
      clearInterval(timeInterval);
    }
  }

  // Handle back button and history changes
  window.addEventListener('popstate', () => {
    forceHideLoader();
  });

  // Backup check - hide loader if page becomes visible and loader is still active
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && isLoaderActive) {
      console.log('Page visibility changed, checking loader state');
      // Add a small delay to allow other events to complete
      setTimeout(() => {
        if (isLoaderActive) {
          forceHideLoader();
        }
      }, 300);
    }
  });

  // Updated loading animation function with synchronized progress and time
  function startLoadingAnimation() {
    let progress = 0;
    const startTime = Date.now();
    const totalSeconds = minimumDisplayTime / 1000;
    
    // Reset elements
    percentElement.textContent = '0%';
    progressBar.style.width = '0%';
    timeElement.textContent = Math.ceil(totalSeconds) + 's';
    
    progressInterval = setInterval(() => {
      const elapsedTime = Date.now() - startTime;
      progress = Math.min((elapsedTime / minimumDisplayTime) * 100, 99); // Cap at 99% during loading
      
      percentElement.textContent = Math.round(progress) + '%';
      progressBar.style.width = progress + '%';
      
      // Sync time remaining with percentage
      const percentRemaining = 100 - progress;
      const secondsRemaining = Math.ceil((percentRemaining / 100) * totalSeconds);
      timeElement.textContent = secondsRemaining + 's';
      
      if (progress >= 99) {
        clearInterval(progressInterval);
      }
    }, 50); // Update every 50ms for smoother animation
  }
  
  // Auto hide the loader if it gets stuck for any reason
  setInterval(() => {
    if (isLoaderActive) {
      const elapsedTime = Date.now() - loaderStartTime;
      if (elapsedTime > 15000) { // 15 seconds max display time
        forceHideLoader();
      }
    }
  }, 5000); // Check every 5 seconds

  // Standard Turbo Drive navigation events
  document.addEventListener('turbo:visit', () => {
    showLoader();
  });
  
  document.addEventListener('turbo:load', () => {
    hideLoader();
  });

  // Handle turbo:before-cache to make sure loader is hidden before caching
  document.addEventListener('turbo:before-cache', () => {
    forceHideLoader();
  });
  
  // Alternative approach: intercept all link clicks
  document.addEventListener('click', (event) => {
    // Check if the clicked element is a link
    let element = event.target;
    while (element && element !== document.body) {
      if (element.tagName.toLowerCase() === 'a' && 
          element.href && 
          !element.target && 
          element.href.startsWith(window.location.origin)) {
        // Check if the link or any of its parents have the data-no-loader attribute
        let hasNoLoader = false;
        let parentElement = element;
        while (parentElement && parentElement !== document.body) {
          if (parentElement.hasAttribute('data-no-loader')) {
            hasNoLoader = true;
            break;
          }
          parentElement = parentElement.parentElement;
        }

        if (!hasNoLoader) {
          showLoader();
        } else {
        }
        break;
      }
      element = element.parentElement;
    }
  });
  
  // For form submissions
  document.addEventListener('submit', (event) => {
    if (event.target.tagName.toLowerCase() === 'form' && 
        !event.target.hasAttribute('data-no-loader')) {
      showLoader();
    }
  });
}


// Initialize only once on page load
document.addEventListener('DOMContentLoaded', initializeLoader);
