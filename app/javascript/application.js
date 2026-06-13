import "@hotwired/turbo-rails"
import "@hotwired/stimulus"
import * as ActionCable from "@rails/actioncable"
window.ActionCable = ActionCable
import "./controllers"
import "./channels/index"
