import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Dropdown controller connected")
    if (this.hasMenuTarget) this.menuTarget.classList.add("hidden")
    this._boundHide = this.hide.bind(this)
    document.addEventListener("click", this._boundHide)
  }

  disconnect() {
    document.removeEventListener("click", this._boundHide)
  }

  toggle(event) {
    event.stopPropagation() // prevents immediate closing
    if (this.hasMenuTarget) this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (this.hasMenuTarget && !this.menuTarget.classList.contains("hidden") && !this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
