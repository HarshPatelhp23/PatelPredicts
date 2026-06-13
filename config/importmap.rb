# config/importmap.rb
# Pin your main application
pin "application", preload: true

# Pin Rails defaults
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Pin ActionCable
pin "@rails/actioncable", to: "actioncable.esm.js"

pin_all_from "app/javascript/channels", under: "channels"

# Pin all controllers
pin_all_from "app/javascript/controllers", under: "controllers"

# If you have any other directories, pin them too
# pin_all_from "app/javascript/custom", under: "custom"
