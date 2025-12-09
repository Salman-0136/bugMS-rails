// Rails / Turbo
import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// Stimulus
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Start Stimulus
const application = Application.start()

// Make it globally accessible for console debugging
window.Stimulus = application

// Load all controllers from app/javascript/controllers
eagerLoadControllersFrom("controllers", application)

export { application }
