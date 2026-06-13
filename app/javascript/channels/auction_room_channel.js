// app/javascript/channels/auction_room_channel.js
//
// ── DUPLICATE SUBSCRIPTION ROOT CAUSE ────────────────────────────────────
// Your compiled application.js already contains this file (confirmed in the
// bundle you shared). So when the page loads, DOMContentLoaded fires
// auctionRoomChannel.init() from the bundle = subscription #1.
//
// A second subscription forms if ANY of these are true:
//   a) A <script> tag on the page imports this file again
//   b) application.js imports it AND a separate pack also imports it
//   c) Turbo Drive navigates without a full page reload, causing
//      DOMContentLoaded to fire a second time on some setups
//
// The `if (this.subscription) return` guard below stops multiple
// subscriptions from forming regardless of cause.
//
// ACTION REQUIRED: search your codebase for any extra
//   import './channels/auction_room_channel'
// or <script> tags pointing to this file and remove duplicates.
// ─────────────────────────────────────────────────────────────────────────

import consumer from "./consumer";


const RANK_LABELS  = ["🥇 1st", "🥈 2nd", "🥉 3rd", "4th", "5th"];
const RANK_COLORS  = ["gold-team", "silver-team", "bronze-team", "green-team", ""];
const RANK_CLASSES = ["gold-rank", "silver-rank", "bronze-rank", "green-rank", ""];

const auctionRoomChannel = {
  subscription: null,

  init() {
    if (this.subscription) {
      console.warn("AuctionRoomChannel: subscription already exists, skipping duplicate init");
      return;
    }
    this.subscription = consumer.subscriptions.create("AuctionRoomChannel", {

      connected() {
        document.body.classList.add("cable-connected");
      },

      disconnected() {
        document.body.classList.remove("cable-connected");
      },

      received(data) {
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
        //    The main team feed cards stay in their fixed DOM positions.
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
      // 1. UPDATE ONE TEAM CARD — purse + skill bars only, no DOM move
      // Scoped to #team-{id} to avoid matching rank strip cards.
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
      // 2. UPDATE WIN % NUMBERS on every team card + sidebar (no reorder)
      // winMap = { "user_id_string": float, ... }
      // ─────────────────────────────────────────────────────────────────
      updateAllWinPercentages(winMap) {
        Object.entries(winMap).forEach(([userId, pct]) => {
          const val = parseFloat(pct);
          if (isNaN(val)) return;

          const pct1 = val.toFixed(1);   // "41.8"
          const pct0 = Math.round(val);  // 42

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

          // Rankings strip ring (number only — % sign is a sibling span)
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
      // 3. REORDER THE TOP RANKINGS STRIP by win % (highest = position 1)
      //
      // rankings = [{ user_id, rank, winning_percentage }, ...]
      // already sorted highest-first from the server.
      //
      // We physically reorder the small rank cards in #at-rankings-grid
      // AND update their colour classes and ring values.
      //
      // The MAIN TEAM FEED CARDS are NOT moved — they stay in the
      // order the server rendered them (your fixed team order).
      // ─────────────────────────────────────────────────────────────────
      reorderRankingsStrip(rankings) {
        const grid = document.getElementById("at-rankings-grid");
        if (!grid) return;

        // Build lookup: user_id → ranking data
        const rankMap = {};
        rankings.forEach(r => { rankMap[String(r.user_id)] = r; });

        // Grab all current rank cards
        const cards = Array.from(grid.querySelectorAll(".at-rank-card"));

        // Sort them by the new rank
        cards.sort((a, b) => {
          const ra = rankMap[a.dataset.userId]?.rank ?? 999;
          const rb = rankMap[b.dataset.userId]?.rank ?? 999;
          return ra - rb;
        });

        // Clear and re-insert in new order
        grid.innerHTML = "";

        cards.forEach((card, i) => {
          const rd = rankMap[card.dataset.userId];
          if (!rd) {
            grid.appendChild(card);
            return;
          }

          const pctFloat = parseFloat(rd.winning_percentage);

          // Update rank label (#1, #2 …)
          const rankLabel = card.querySelector("[data-rank-label]");
          if (rankLabel) rankLabel.textContent = `#${rd.rank}`;

          // Update ring fill
          const ringFill = card.querySelector("[data-ring-fill]");
          if (ringFill) ringFill.setAttribute("stroke-dasharray", `${pctFloat}, 100`);

          // Update ring number (number span only, not the % span)
          const winNum = card.querySelector("[data-win-pct]");
          if (winNum) winNum.textContent = Math.round(pctFloat);

          // Swap colour class to match new position
          card.classList.remove(...RANK_CLASSES.filter(c => c));
          if (RANK_CLASSES[i]) card.classList.add(RANK_CLASSES[i]);

          // Animate in staggered
          card.style.opacity   = "0";
          card.style.transform = "translateY(10px)";
          grid.appendChild(card);

          setTimeout(() => {
            card.style.transition = "opacity 0.35s ease, transform 0.35s ease";
            card.style.opacity    = "1";
            card.style.transform  = "translateY(0)";
          }, i * 60);
        });
      },

      // ─────────────────────────────────────────────────────────────────
      // 4. ADD NEW PLAYER CARD
      // Always builds locally with at- classes (never uses server HTML
      // because _auction_room partial used old class names).
      // ─────────────────────────────────────────────────────────────────
      handleNewPlayer(data) {
        const teamCard = document.querySelector(`#team-${data.user_id}`);
        if (!teamCard) return;

        const grid = teamCard.querySelector("[data-players-grid]");
        if (!grid) return;

        const name = data.player_name || "";

        // Duplicate guard
        if (grid.querySelector(`[data-player="${CSS.escape(name)}"]`)) return;

        const card = this.buildPlayerCard(data);
        if (!card) return;

        card.style.opacity   = "0";
        card.style.transform = "translateY(14px)";
        grid.appendChild(card);

        requestAnimationFrame(() => {
          card.style.transition = "opacity 0.35s ease, transform 0.35s ease";
          card.style.opacity    = "1";
          card.style.transform  = "translateY(0)";
        });

        // Bump squad count badge
        const countEl = teamCard.querySelector("[data-squad-count]");
        if (countEl) {
          const n = parseInt(countEl.textContent) || 0;
          countEl.textContent = `${n + 1} Players`;
        }
      },

      buildPlayerCard(data) {
        const isCaptain  = !!data.is_captain;
        const insight    = isCaptain ? "captain" : (data.purchase_insight || "worst_buy");
        const bat        = data.batting  ?? 0;
        const bowl       = data.bowling  ?? 0;
        const price      = isCaptain
          ? `<span class="at-captain-pill">Captain</span>`
          : (data.price_display || "");

        const card = document.createElement("div");
        card.className      = "at-player-card";
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
  }
};

// ── BOOT ──────────────────────────────────────────────────────────────────
// DOMContentLoaded fires once per page load from the compiled bundle.
// The subscription guard inside init() stops any accidental second call.
document.addEventListener("DOMContentLoaded", () => {
  console.log("DOM ready — init AuctionRoomChannel");
  auctionRoomChannel.init();
});
