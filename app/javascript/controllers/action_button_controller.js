import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "spinner"];
  static values = { resetAfter: Number };

  activate() {
    this.element.disabled = true;
    if (this.hasIconTarget) this.iconTarget.classList.add("hidden");
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.remove("hidden");
    this.dispatch("activated");

    if (this.resetAfterValue > 0) {
      setTimeout(() => this.reset(), this.resetAfterValue);
    }
  }

  reset() {
    this.element.disabled = false;
    if (this.hasIconTarget) this.iconTarget.classList.remove("hidden");
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.add("hidden");
  }
}
