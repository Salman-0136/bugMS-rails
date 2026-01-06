// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"
import Chartkick from "chartkick"
import Chart from "chart.js/auto"
import "chartjs-adapter-date-fns"

Chartkick.use(Chart)

export default class extends Controller {
  connect() {
    console.log("Dashboard controller connected!")
    window.Chartkick = Chartkick
    console.log("Chartkick assigned to window:", window.Chartkick)
    console.log("Checking if charts exist...")
    // Force redraw found charts if any
    if (window.Chartkick && window.Chartkick.charts) {
      console.log("Existing charts:", Object.keys(window.Chartkick.charts))
    }
  }
}
