import { Controller } from "@hotwired/stimulus";

const MELBOURNE = { lat: -37.8136, lng: 144.9631 };

export default class extends Controller {
  static targets = [
    "steps",
    "locationIcon",
    "locationDetail",
    "dataStep",
    "dataIcon",
    "audioStep",
    "audioIcon",
  ];

  locateUser() {
    this.stepsTarget.classList.remove("hidden");
    this.#setStatus(this.locationIconTarget, "active");

    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        ({ coords }) => this.#show(coords.latitude, coords.longitude, "GPS"),
        () => this.#tryIpGeolocation(),
      );
    } else {
      this.#tryIpGeolocation();
    }
  }

  async #tryIpGeolocation() {
    try {
      const res = await fetch("/journey/locate");
      const data = await res.json();
      if (data.lat && data.lng) {
        this.#show(data.lat, data.lng, "IP");
      } else {
        this.#fallback();
      }
    } catch {
      this.#fallback();
    }
  }

  #fallback() {
    this.#show(MELBOURNE.lat, MELBOURNE.lng, "Melbourne default");
  }

  #show(lat, lng, source) {
    this.#setStatus(this.locationIconTarget, "done");
    this.locationDetailTarget.textContent = `${lat.toFixed(4)}, ${lng.toFixed(4)}  ·  ${source}`;
    this.locationDetailTarget.classList.remove("hidden");

    this.dataStepTarget.classList.remove("opacity-40");
    this.#setStatus(this.dataIconTarget, "active");
  }

  #setStatus(el, status) {
    el.dataset.status = status;
  }
}
