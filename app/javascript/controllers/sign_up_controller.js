import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["password", "passwordConfirmation"];

  submit(event) {
    const form = this.element;
    const password = this.passwordTarget;
    const passwordConfirmation = this.passwordConfirmationTarget;

    if (password.value !== passwordConfirmation.value) {
      passwordConfirmation.setCustomValidity("Passwords do not match");
    } else {
      passwordConfirmation.setCustomValidity("");
    }

    if (!form.checkValidity()) {
      event.preventDefault();
      event.stopPropagation();
      form.classList.add("was-validated");
    }
  }
}
