import "@hotwired/turbo-rails"
// import "./controllers"
// import "./channels"


// app/assets/javascripts/application.js
// This is the complete converted code - no imports needed!

// Wait for both DOM and ActionCable to be ready
document.addEventListener("DOMContentLoaded", function() {
  console.log("DOM ready — initializing AuctionRoomChannel");
  
  // Check if ActionCable is available
  if (typeof ActionCable === 'undefined') {
    console.error("ActionCable not loaded! Make sure the CDN script is included.");
    return;
  }
  
  // Create consumer
  const cable = ActionCable.createConsumer('/cable');
  
  // Constants
  const RANK_LABELS = ["🥇 1st", "🥈 2nd", "🥉 3rd", "4th", "5th"];
  const RANK_COLORS = ["gold-team", "silver-team", "bronze-team", "green-team", ""];
  const RANK_CLASSES = ["gold-rank", "silver-rank", "bronze-rank", "green-rank", ""];
  
  // Create subscription
  let subscription = null;
  
  // Create the subscription
  subscription = cable.subscriptions.create("AuctionRoomChannel", {
    connected() {
      console.log("✅ Connected to AuctionRoomChannel");
      document.body.classList.add("cable-connected");
    },

    disconnected() {
      console.log("❌ Disconnected from AuctionRoomChannel");
      document.body.classList.remove("cable-connected");
    },

    received(data) {
      console.log("📩 Received data:", data);
      this.handleDataUpdate(data);
    },

    // ─────────────────────────────────────────────────────────────────
    // DISPATCH
    // ─────────────────────────────────────────────────────────────────
    handleDataUpdate(data) {
      // 1. Update buying team's purse + skill bars (in place, no reorder)
      if (data.user_id) {
        this.updateTeamCard(data);
      }

      // 2. Update win % numbers on every team card (in place, no reorder)
      if (data.winning_percentage) {
        this.updateAllWinPercentages(data.winning_percentage);
      }

      // 3. Reorder the TOP rankings strip by win % (highest first)
      if (data.rankings && data.rankings.length > 0) {
        this.reorderRankingsStrip(data.rankings);
      }

      // 4. Insert new player card into buying team's squad grid
      if (data.player_name && data.user_id) {
        this.handleNewPlayer(data);
      }

      // 5. Show toast
      if (data.notification) {
        this.showNotification(data.notification);
      }
    },

    // ─────────────────────────────────────────────────────────────────
    // 1. UPDATE ONE TEAM CARD
    // ─────────────────────────────────────────────────────────────────
    updateTeamCard(data) {
      const card = document.querySelector(`#team-${data.user_id}`);
      if (!card) return;

      if (data.remaining_purse != null) {
        const el = card.querySelector("[data-remaining-purse]");
        if (el) el.textContent = data.remaining_purse;
      }

      if (data.team_batting != null) {
        const bar = card.querySelector("[data-bat-bar]");
        if (bar) {
          bar.style.width = `${data.team_batting}%`;
          const lbl = bar.querySelector("[data-bat-bar-label]");
          if (lbl) lbl.textContent = `${data.team_batting}%`;
        }
      }

      if (data.team_bowling != null) {
        const bar = card.querySelector("[data-bowl-bar]");
        if (bar) {
          bar.style.width = `${data.team_bowling}%`;
          const lbl = bar.querySelector("[data-bowl-bar-label]");
          if (lbl) lbl.textContent = `${data.team_bowling}%`;
        }
      }
    },

    // ─────────────────────────────────────────────────────────────────
    // 2. UPDATE WIN % NUMBERS
    // ─────────────────────────────────────────────────────────────────
    updateAllWinPercentages(winMap) {
      Object.entries(winMap).forEach(([userId, pct]) => {
        const val = parseFloat(pct);
        if (isNaN(val)) return;

        const pct1 = val.toFixed(1);
        const pct0 = Math.round(val);

        // Main team card
        const teamCard = document.querySelector(`#team-${userId}`);
        if (teamCard) {
          const n = teamCard.querySelector("[data-win-pct-num]");
          if (n) n.textContent = `${pct1}%`;
          const c = teamCard.querySelector("[data-win-chance]");
          if (c) c.textContent = `${pct1}%`;
        }

        // Sidebar
        const sidebarItem = document.querySelector(`#nav-${userId}`);
        if (sidebarItem) {
          const p = sidebarItem.querySelector("[data-sidebar-pct]");
          if (p) p.textContent = `${pct1}% win`;
          const b = sidebarItem.querySelector("[data-sidebar-bar]");
          if (b) b.style.width = `${val}%`;
        }

        // Rankings strip ring
        const rankCard = document.querySelector(`#at-rankings-grid [data-user-id="${userId}"]`);
        if (rankCard) {
          const fill = rankCard.querySelector("[data-ring-fill]");
          if (fill) fill.setAttribute("stroke-dasharray", `${val}, 100`);
          const num = rankCard.querySelector("[data-win-pct]");
          if (num) num.textContent = pct0;
        }
      });
    },

    // ─────────────────────────────────────────────────────────────────
    // 3. REORDER RANKINGS STRIP
    // ─────────────────────────────────────────────────────────────────
    reorderRankingsStrip(rankings) {
      const grid = document.getElementById("at-rankings-grid");
      if (!grid) return;

      const rankMap = {};
      rankings.forEach(r => { rankMap[String(r.user_id)] = r; });

      const cards = Array.from(grid.querySelectorAll(".at-rank-card"));

      cards.sort((a, b) => {
        const ra = rankMap[a.dataset.userId]?.rank ?? 999;
        const rb = rankMap[b.dataset.userId]?.rank ?? 999;
        return ra - rb;
      });

      grid.innerHTML = "";

      cards.forEach((card, i) => {
        const rd = rankMap[card.dataset.userId];
        if (!rd) {
          grid.appendChild(card);
          return;
        }

        const pctFloat = parseFloat(rd.winning_percentage);

        const rankLabel = card.querySelector("[data-rank-label]");
        if (rankLabel) rankLabel.textContent = `#${rd.rank}`;

        const ringFill = card.querySelector("[data-ring-fill]");
        if (ringFill) ringFill.setAttribute("stroke-dasharray", `${pctFloat}, 100`);

        const winNum = card.querySelector("[data-win-pct]");
        if (winNum) winNum.textContent = Math.round(pctFloat);

        card.classList.remove(...RANK_CLASSES);
        if (RANK_CLASSES[i]) card.classList.add(RANK_CLASSES[i]);

        card.style.opacity = "0";
        card.style.transform = "translateY(10px)";
        grid.appendChild(card);

        setTimeout(() => {
          card.style.transition = "opacity 0.35s ease, transform 0.35s ease";
          card.style.opacity = "1";
          card.style.transform = "translateY(0)";
        }, i * 60);
      });
    },

    // ─────────────────────────────────────────────────────────────────
    // 4. ADD NEW PLAYER CARD
    // ─────────────────────────────────────────────────────────────────
    handleNewPlayer(data) {
      const teamCard = document.querySelector(`#team-${data.user_id}`);
      if (!teamCard) return;

      const grid = teamCard.querySelector("[data-players-grid]");
      if (!grid) return;

      const name = data.player_name || "";

      if (grid.querySelector(`[data-player="${CSS.escape(name)}"]`)) return;

      const card = this.buildPlayerCard(data);
      if (!card) return;

      card.style.opacity = "0";
      card.style.transform = "translateY(14px)";
      grid.appendChild(card);

      requestAnimationFrame(() => {
        card.style.transition = "opacity 0.35s ease, transform 0.35s ease";
        card.style.opacity = "1";
        card.style.transform = "translateY(0)";
      });

      const countEl = teamCard.querySelector("[data-squad-count]");
      if (countEl) {
        const n = parseInt(countEl.textContent) || 0;
        countEl.textContent = `${n + 1} Players`;
      }
    },

    buildPlayerCard(data) {
      const isCaptain = !!data.is_captain;
      const insight = isCaptain ? "captain" : (data.purchase_insight || "worst_buy");
      const bat = data.batting ?? 0;
      const bowl = data.bowling ?? 0;
      const price = isCaptain
        ? `<span class="at-captain-pill">Captain</span>`
        : (data.price_display || "");

      const card = document.createElement("div");
      card.className = "at-player-card";
      card.dataset.player = data.player_name;

      card.innerHTML = `
        <div class="at-player-insight">
          <img src="/assets/${insight}.jpeg" class="at-insight-img" alt="${insight}">
        </div>
        <div class="at-player-av-wrap">
          <img src="/assets/default_player_image.jpeg" class="at-player-av" alt="${data.player_name}">
          ${isCaptain ? '<div class="at-captain-badge">👑</div>' : ""}
        </div>
        <div class="at-player-info">
          <div class="at-player-name">${data.player_name}</div>
          <div class="at-player-price">${price}</div>
        </div>
        <div class="at-player-skills">
          <div class="at-mini-skill">
            <div class="at-mini-track">
              <div class="at-mini-bar bat-mini" style="width:${bat}%"></div>
            </div>
            <div class="at-mini-label">Bat ${bat}%</div>
          </div>
          <div class="at-mini-skill">
            <div class="at-mini-track">
              <div class="at-mini-bar bowl-mini" style="width:${bowl}%"></div>
            </div>
            <div class="at-mini-label">Bowl ${bowl}%</div>
          </div>
        </div>
      `;
      return card;
    },

    // ─────────────────────────────────────────────────────────────────
    // 5. TOAST NOTIFICATION
    // ─────────────────────────────────────────────────────────────────
    showNotification(message) {
      const container = document.getElementById("at-notifications");
      if (!container) return;

      const toast = document.createElement("div");
      toast.className = "at-toast";
      toast.innerHTML = `
        <div class="at-toast-icon">🔔</div>
        <div class="at-toast-text">${message}</div>
      `;
      container.appendChild(toast);

      setTimeout(() => {
        toast.style.animation = "at-toast-out 0.3s ease-out forwards";
        setTimeout(() => toast.remove(), 320);
      }, 5000);
    }
  });
});
