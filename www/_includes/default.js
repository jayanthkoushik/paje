function getPreferredTheme() {
  const storedTheme = localStorage.getItem("theme");
  if (storedTheme === "dark" || storedTheme === "light") {
    return storedTheme;
  }
  return "auto";
}

function setTheme(theme) {
  var coreTheme;
  if (theme === "dark" || theme === "light") {
    coreTheme = theme;
  } else if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
    coreTheme = "dark";
  } else {
    coreTheme = "light";
  }

  // Set global theme.
  document.documentElement.setAttribute("data-bs-theme", coreTheme);

  // Update themed images.
  const themeSrc = coreTheme === "dark" ? "data-darksrc" : "data-lightsrc";
  document.querySelectorAll("img[data-darksrc]").forEach((img) => {
    const newSrc = img.getAttribute(themeSrc);
    if (newSrc && img.getAttribute("src") !== newSrc) {
      img.setAttribute("src", newSrc);
      img.classList.remove("hidden");
    }
  });

  // Update theme selector.
  document.querySelectorAll(".theme-button").forEach((themeBtn) => {
    if (themeBtn.getAttribute("data-bs-theme-value") === theme) {
      themeBtn.classList.add("active");
      const themeSvg = themeBtn.querySelector("svg");
      document.querySelector("#active-theme-button svg").innerHTML =
        themeSvg.innerHTML;
    } else {
      themeBtn.classList.remove("active");
    }
  });
}

window.addEventListener("DOMContentLoaded", () => {
  const themeSelector = document
    .getElementById("theme-selector-template")
    .content.cloneNode(true);
  document
    .getElementById("theme-selector-container")
    .appendChild(themeSelector);

  setTheme(getPreferredTheme());

  document.querySelectorAll(".author a").forEach((authorLink) => {
    authorLink.setAttribute("tabindex", "0");
    authorLink.setAttribute("role", "button");
    authorLink.setAttribute("class", "author-link");
  });

  const tooltips = [
    ...document.querySelectorAll('[data-bs-toggle="tooltip"'),
  ].map((tooltipTrigger) => {
    const tooltip = new bootstrap.Tooltip(tooltipTrigger);
    tooltipTrigger.addEventListener("inserted.bs.tooltip", (e) => {
      // Theme tooltip contents opposite to the body theme.
      const coreTheme = document.documentElement.getAttribute("data-bs-theme");
      const tooltipInner =
        tooltip.tip.getElementsByClassName("tooltip-inner")[0];
      tooltipInner.setAttribute(
        "data-bs-theme",
        coreTheme === "dark" ? "light" : "dark"
      );
    });
    return tooltip;
  });
  const popovers = [
    ...document.querySelectorAll('[data-bs-toggle="popover"]'),
  ].map((popoverTrigger) => new bootstrap.Popover(popoverTrigger));

  document
    .querySelectorAll(".citation a, a.footnote-ref")
    .forEach((citLink) => {
      citLink.removeAttribute("href");
    });
  document.querySelectorAll("#footnotes, .inst-nojs").forEach((nojsElem) => {
    nojsElem.remove();
  });

  document.querySelectorAll(".theme-button").forEach((themeBtn) => {
    themeBtn.addEventListener("click", function () {
      const theme = this.getAttribute("data-bs-theme-value");
      if (theme === "dark" || theme === "light") {
        localStorage.setItem("theme", theme);
      } else {
        localStorage.removeItem("theme");
      }
      setTheme(theme);
    });
  });

  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", () => {
      if (getPreferredTheme() === "auto") {
        setTheme("auto");
      }
    });

  const scrollTopBtn = document.getElementById("scroll-to-top");
  window.addEventListener("scroll", () => {
    if (window.scrollY == 0) {
      scrollTopBtn.classList.add("invisible");
    } else {
      scrollTopBtn.classList.remove("invisible");
    }
  });
});
