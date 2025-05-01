#!/usr/bin/env bash
# Import logging utilities
source "$(dirname "${BASH_SOURCE[0]}")/shared/log_utils.sh"


cp /var/lib/snapd/desktop/applications/*.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
gsettings set org.cinnamon.desktop.interface clock-use-24h false
gsettings set org.cinnamon.desktop.interface clock-show-date true
gsettings set org.nemo.preferences default-folder-viewer 'list-view'


current_list=$(gsettings get org.cinnamon.desktop.keybindings custom-list)
# Check if custom0 is already in the list
if echo "$current_list" | grep -q "'custom0'"; then
  log_info "'custom0' already exists in the list of favorite apps."
else
  # Append custom0 to the list using parameter expansion
  new_list="${current_list/]/, 'custom0']}"
  log_info "Adding 'custom0' to favorite apps list: $new_list"
  dconf write /org/cinnamon/favorite-apps "$new_list"
fi

log_success "Cinnamon custom applet added to favorites."


# don't group applications by window
for file in ~/.cinnamon/configs/grouped-window-list@cinnamon.org/*.json; do
  cp "$file" "$file.bak"
  jq '.["group-apps"].value = false' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done

sudo apt install --reinstall -o Dpkg::Options::="--force-confmiss" grub2-theme-mint