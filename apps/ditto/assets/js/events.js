import topbar from "topbar";

export function registerTopbar() {
  topbar.config({
    barColors: { 0: "#29d" },
    shadowColor: "rgba(0, 0, 0, .3)",
  });

  window.addEventListener("phx:page-loading-start", () => {
    topbar.show(400);
  });

  window.addEventListener("phx:page-loading-stop", () => {
    topbar.hide();
  });
}
