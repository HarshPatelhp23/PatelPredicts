function toggleContent() {
  const content = document.getElementById("hiddenContent");
  const button = document.getElementById("toggleButton");
  
  if (content.style.display === "none") {
    content.style.display = "block";
    button.textContent = "Hide Points Overview";
  } else {
    content.style.display = "none";
    button.textContent = "View Points Overview";
  }
}