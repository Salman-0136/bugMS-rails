import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
const application = Application.start()

// Manual controller registration for ESBuild
import DashboardController from "./controllers/dashboard_controller"
application.register("dashboard", DashboardController)

import DropdownController from "./controllers/dropdown_controller"
application.register("dropdown", DropdownController)

window.Stimulus = application
export { application }
