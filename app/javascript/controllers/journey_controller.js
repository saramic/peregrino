import { Controller } from "@hotwired/stimulus";

const MELBOURNE = { lat: -37.8136, lng: 144.9631 };

export default class extends Controller {
  static targets = [
    "steps",
    "locationIcon",
    "locationDetail",
    "dataStep",
    "dataIcon",
    "dataDetail",
    "audioStep",
    "audioIcon",
    "startControls",
    "audioControls",
    "pauseIcon",
    "playIcon",
    "pauseLabel",
  ];

  #paused = false;

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

  togglePause() {
    if (this.#paused) {
      window.speechSynthesis?.resume();
      this.pauseIconTarget.classList.remove("hidden");
      this.playIconTarget.classList.add("hidden");
      this.pauseLabelTarget.textContent = "Pause";
    } else {
      window.speechSynthesis?.pause();
      this.pauseIconTarget.classList.add("hidden");
      this.playIconTarget.classList.remove("hidden");
      this.pauseLabelTarget.textContent = "Resume";
    }
    this.#paused = !this.#paused;
  }

  restart() {
    window.speechSynthesis?.cancel();
    window.location.reload();
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

    this.#fetchNarrative(lat, lng);
  }

  async #fetchNarrative(lat, lng) {
    try {
      const res = await fetch(`/journey/narrate?lat=${lat}&lng=${lng}`);
      if (!res.ok) return;
      const data = await res.json();
      if (!data.place) return;

      this.#setStatus(this.dataIconTarget, "done");
      this.dataDetailTarget.textContent = data.place;
      this.dataDetailTarget.classList.remove("hidden");

      this.audioStepTarget.classList.remove("opacity-40");
      this.#setStatus(this.audioIconTarget, "active");

      if (data.summary) this.#speak(data.summary);
    } catch {
      // leave data step spinning — best effort
    }
  }

  #speak(text) {
    this.element.dataset.pendingNarrative = text;
    this.startControlsTarget.classList.add("hidden");
    this.audioControlsTarget.classList.remove("hidden");
    try {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.onend = () => this.#setStatus(this.audioIconTarget, "done");
      window.speechSynthesis.speak(utterance);
    } catch {
      // SpeechSynthesis unavailable in this environment
    }
  }

  #setStatus(el, status) {
    el.dataset.status = status;
  }
}
