# Open external links in Dia Mini

Open web links from other apps in a temporary Mini window first, like Little Arc. Use **Open in Dia** to keep a page as a normal tab.

Enable **Settings → Patches → Browsing → Dia Mini → Open external links in Dia Mini**, or `diatweaks enable diaMiniExternalLinks`. It requires **Dia Mini** and is off by default.

This applies to HTTP and HTTPS links sent to Dia by other apps. Links clicked inside webpages keep their usual behavior. Special app URLs, local files and other schemes keep Dia’s normal opening path.

During startup, web links wait for the selected browser profile to become ready. If Mini cannot open them within 30 seconds, or the option is turned off while they wait, Dia opens them normally. Each link is delivered once.

To check it, open a web link from another app with this option off, then on. With it on, a Mini window should open; **Open in Dia** should keep the live page as a tab. Turn **Dia Mini** off and confirm links return to their usual behavior.
