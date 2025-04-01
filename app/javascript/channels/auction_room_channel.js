import consumer from "./consumer";

const auctionRoomChannel = consumer.subscriptions.create("AuctionRoomChannel", {
  connected() {
    console.log("Connected to AuctionRoomChannel");
  },

  disconnected() {
    console.log("Disconnected from AuctionRoomChannel");
  },

  received(data) {
    console.log("Received data:=====", data);
    const { player_name, notification, player_html, user_id, remaining_purse, batting, bowling, purchase_insight, winning_percentage, max_bid } = data;
    console.log('value of max bid is:-', max_bid)

    // Locate the user card in the DOM
    const userCardContainer = document.querySelector(`[data-user-id='${user_id}']`);
    if (!userCardContainer) {
      // console.error(`User card container not found for User ID: ${user_id}`);
      return;
    }

    // Locate the players list in the user's card
    const playersList = userCardContainer.querySelector(".list-group");
    if (!playersList) {
      // console.error("Players list not found in the user's card.");
      return;
    }

    const regex = /₹\d+\.\d{2} \(\w+\)/;
    const match = player_html.match(regex);

    const existingPlayer = playersList.querySelector(`[data-player-name='${player_name}']`);
    if (existingPlayer) {
      // console.log("Player card already exists, skipping creation.");
      return;
    }

    // Create a new list item for the player
    const newPlayerItem = document.createElement("li");
    newPlayerItem.classList.add(
      "list-group-item",
      "auction-player-item",
      "d-flex",
      "align-items-center",
      "justify-content-between",
      "border",
      "rounded",
      "shadow-sm",
      "mb-2"
      // "ml-4"
    );
    newPlayerItem.setAttribute("data-player-name", player_html.trim().split(" - ")[0]);
    newPlayerItem.style.padding = "10px";

    newPlayerItem.innerHTML = `
      <div class="d-flex w-100 justify-content-between align-items-center">
        <!-- Section 1: Image, Name, and Price -->
        <div class="d-flex align-items-center" style="flex: 1; margin-right: 20px;">
          <img src="/assets/default_player_image.jpeg" 
               class="player-image rounded-circle"
               alt="default_player_image.jpeg"
               style="width: 50px; height: 50px; object-fit: cover; border: 2px solid #007bff; margin-right: 15px;">
          <div>
            <div class="fw-bold">${player_html.trim().split(" - ")[0]}</div>
            <div class="text-muted fw-bold">
              ${
                match && match[0] === "₹0.00 (crores)"
                  ? `<span class="captain-badge">👑 Captain</span>`
                  : `${match ? match[0] : "👑 Captain"}`
              }
            </div>
          </div>
        </div>

        <!-- Section 2: Batting and Bowling Progress Bars -->
        <div class="progress-section d-flex flex-column text-center" style="flex: 1; margin-right: 20px; margin-right: 30px;">
          <div class="mb-2">
            <span class="small text-muted">Batting:</span>
            <div class="progress" style="height: 18px;">
              <div class="progress-bar bg-success" style="width: ${batting}%;">${batting}%</div>
            </div>
          </div>
          <div>
            <span class="small text-muted">Bowling:</span>
            <div class="progress" style="height: 18px;">
              <div class="progress-bar bg-warning" style="width: ${bowling}%;">${bowling}%</div>
            </div>
          </div>
        </div>

        <!-- Section 3: Insight Image -->
        <div style="flex: 0 0 50px; display: flex; justify-content: center; align-items: center;">
          <img src="/assets/${purchase_insight}.jpeg"
               alt="${purchase_insight}" 
               class="rounded-circle shadow-sm"
               style="width: 50px; height: 50px;">
        </div>
      </div>
    `;

    // Append the new player to the list
    playersList.appendChild(newPlayerItem);

    // Update remaining purse on the user's original card
    const remainingPurseElement = userCardContainer.querySelector(".remaining-purse");
    if (remainingPurseElement) {
      remainingPurseElement.textContent = remaining_purse;
    }

    // Update winning percentage in the user's original card
    Object.entries(winning_percentage).forEach(([id, percentage]) => {
      const userCardContainer = document.querySelector(`[data-user-id='${id}']`);
      if (userCardContainer) {
        const winningChancesElement = userCardContainer.querySelector(".winning-chances");
        if (winningChancesElement) {
          winningChancesElement.textContent = `${percentage}`;
        }
      } else {
        console.error(`User card container not found for User ID: ${id}`);
      }
    });

    // Update captain's max bid in the user's original card
    Object.entries(max_bid).forEach(([id, max_bid]) => {
      const userCardContainer = document.querySelector(`[data-user-id='${id}']`);
      if (userCardContainer) {
        const wmaxBidElement = userCardContainer.querySelector(".max-bid");
        if (wmaxBidElement) {
          wmaxBidElement.textContent = `${max_bid}`;
        }
      } else {
        console.error(`User card container not found for User ID: ${id}`);
      }
    });

    // Update team batting percentage
    const teamBatting = document.querySelector(`.team-batting[data-user-id="${user_id}"]`);
    if (teamBatting) {
      teamBatting.style.width = `${data.team_batting}%`;
      teamBatting.textContent = `${data.team_batting}%`;
    }

    // Update team bowling percentage
    const teamBowling = document.querySelector(`.team-bowling[data-user-id="${user_id}"]`);
    if (teamBowling) {
      teamBowling.style.width = `${data.team_bowling}%`;
      teamBowling.textContent = `${data.team_bowling}%`;
    }

    // Update team rankings dynamically
  const updateRankings = () => {
    const rankingsContainer = document.querySelector(".team-rankings-container");
    if (!rankingsContainer) return;

    // Sort users based on their winning percentages
    const sortedUsers = Object.entries(winning_percentage)
      .sort((a, b) => parseFloat(b[1]) - parseFloat(a[1])); // Sort descending

    // Clear existing rankings
    rankingsContainer.innerHTML = "";

    // Re-render the rankings dynamically
    const colorClasses = ["text-bg-primary", "text-bg-success", "text-bg-warning", "text-bg-danger"];

    sortedUsers.forEach(([id, percentage], index) => {
      // Find the user card in the DOM
      const userCard = document.querySelector(`[data-user-id='${id}']`);
      const username = userCard?.querySelector(".card-title")?.textContent || "Unknown";

      // Get a color class based on the index (cyclically)
      const badgeColor = colorClasses[index % colorClasses.length];

      const rankingItem = `
        <div class="col-3 text-center mb-2">
          <div class="card shadow-sm border-0" style="border-radius: 10px;">
            <div class="card-body p-2">
              <h6><span class="fw-bold mb-0 badge badge-sm ${badgeColor} text-uppercase">${username.split(" ").pop()}</span></h6>
              <p class="small mb-1 text-muted">Rank ${index + 1}</p>
              <p class="fw-bold text-danger mb-0">${percentage}</p>
            </div>
          </div>
        </div>
      `;

      // Insert the new ranking card into the rankings container
      const rankingsContainer = document.querySelector(".team-rankings-container");
      console.log('value of ranking', rankingsContainer)
      rankingsContainer.insertAdjacentHTML("beforeend", rankingItem);
    });
  };

  updateRankings();

    // Function to display a toast notification
    const createToast = (message, type = "success") => {
      const container = document.getElementById("notifications");
      if (!container) return;

      const toast = document.createElement("div");
      toast.classList.add("notification-toast", type);
      toast.innerHTML = `
        <div>
          <img src="/assets/default_player_image.jpeg" alt="icon" style="width: 24px; height: 24px;">
        </div>
        <div class="notification-text">${message}</div>
      `;

      container.appendChild(toast);

      // Auto-remove the toast after 4 seconds
      setTimeout(() => {
        toast.remove();
      }, 8000);
    };

    // Display a notification if provided
    if (notification) {
      createToast(notification, "success");
    }
  },
});

export default auctionRoomChannel;
