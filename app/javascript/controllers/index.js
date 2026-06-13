import { application } from "./application"

import AuctionInsightsController from "./auction_insights_controller"
import AuctionStatsController from "./auction_stats_controller"
import CountdownTimerController from "./countdown_timer_controller"
import FlashController from "./flash_controller"
import HelloController from "./hello_controller"
import PlayerCardController from "./player_card_controller"
import SplRegistrationController from "./spl_registration_controller"
import SplSessionController from "./spl_session_controller"

application.register("auction-insights", AuctionInsightsController)
application.register("auction-stats", AuctionStatsController)
application.register("countdown-timer", CountdownTimerController)
application.register("flash", FlashController)
application.register("hello", HelloController)
application.register("player-card", PlayerCardController)
application.register("spl-registration", SplRegistrationController)
application.register("spl-session", SplSessionController)
