#!/bin/bash
# STP: Print the LOUD, unmissable whiteboard URL banner.
# Usage: bash whiteboard-banner.sh ["optional subtitle line"]
# Call this AFTER starting the whiteboard server, as the LAST thing
# printed before handing control back (or before an AskUserQuestion).

SUBTITLE="${1:-It will populate live as we work. Keep it visible.}"

echo ""
echo -e "\033[1;33m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;33m║\033[0m   \033[1;5;93m★ OPEN THE WHITEBOARD NOW ★\033[0m                                \033[1;33m║\033[0m"
echo -e "\033[1;33m║\033[0m                                                              \033[1;33m║\033[0m"
echo -e "\033[1;33m║\033[0m   \033[1;37m▶\033[0m  \033[1;4;94mhttp://localhost:3333\033[0m  \033[1;37m◀\033[0m                             \033[1;33m║\033[0m"
echo -e "\033[1;33m║\033[0m                                                              \033[1;33m║\033[0m"
printf  "\033[1;33m║\033[0m   \033[2;37m%-58s\033[0m \033[1;33m║\033[0m\n" "$SUBTITLE"
echo -e "\033[1;33m╚══════════════════════════════════════════════════════════════╝\033[0m"
echo ""
