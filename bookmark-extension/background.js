chrome.commands.onCommand.addListener((command) => {
  if ((command.name = "copy-url")) {
    chrome.tabs.query({ active: true, currentWindow: true }).then(([tab]) => {
      chrome.scripting.executeScript({
        target: { tabId: tab.id },
        function: () => {
          navigator.clipboard.writeText(location.href);
        },
      });
    });
  }
});
