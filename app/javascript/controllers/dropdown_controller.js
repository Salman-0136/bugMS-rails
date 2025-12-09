import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Dropdown controller connected!", this.element)
  }

  toggle() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("hidden")
    }
  }
}
