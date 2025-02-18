import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  teamSelected(event) {
    const elementIndex = event.params.index;

    const teamSelectElement = document.getElementById(
      "team-select-" + elementIndex
    );
    const ahleteSelectElement = document.getElementById(
      "athlete-select-" + elementIndex
    );

    Array.from(ahleteSelectElement.children).forEach((child) => {
      child.dataset.teamId == teamSelectElement.value
        ? child.classList.remove("d-none")
        : child.classList.add("d-none");
    });

    teamSelectElement.value == 0
      ? ahleteSelectElement.classList.add("d-none")
      : ahleteSelectElement.classList.remove("d-none");
  }
}
