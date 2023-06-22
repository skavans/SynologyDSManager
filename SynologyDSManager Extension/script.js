var clickTarget = null


function handleMessage(event) {
    switch (event.name) {
        case "downloadURL":
            if (clickTarget) {
                var link = clickTarget.closest('a')
                safari.extension.dispatchMessage("downloadURL",  { "URL": link.href });
            }
            clickTarget = null
            break
        default:
            break
    }
}

function handleContextMenu(event) {
    clickTarget = event.target || event.srcElement
}

document.addEventListener("DOMContentLoaded", function(event) {
    safari.self.addEventListener("message", handleMessage);
    document.addEventListener('contextmenu', handleContextMenu);
});
