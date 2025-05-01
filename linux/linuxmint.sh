#!/usr/bin/env bash
# Import logging utilities
source "$(dirname "${BASH_SOURCE[0]}")/shared/log_utils.sh"


cp /var/lib/snapd/desktop/applications/*.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
gsettings set org.cinnamon.desktop.interface clock-use-24h false
gsettings set org.cinnamon.desktop.interface clock-show-date true
gsettings set org.nemo.preferences default-folder-viewer 'list-view'


current_list=$(gsettings get org.cinnamon.desktop.keybindings custom-list)
# Check if the list already contains 'custom0'
if echo "$current_list" | grep -q "'custom0'"; then
  log_info "'custom0' is already in the list"
else
  gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name 'Area Screenshot'
  gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['<Primary>Print']"
  gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command "gnome-screenshot -a"
  # Check if the list is empty
  if [[ "$current_list" == "@as []" ]]; then
    # If the list is empty, create a new list with 'custom0'
    new_list="@as ['custom0']"
  else
    # If the list is not empty, append 'custom0' to the list
    new_list=$(echo "$current_list" | sed "s/]/, 'custom0']/g")
  fi

  # Set the updated list of custom keybindings
  gsettings set org.cinnamon.desktop.keybindings custom-list "$new_list"
fi


# don't group applications by window
for file in ~/.cinnamon/configs/grouped-window-list@cinnamon.org/*.json; do
  cp "$file" "$file.bak"
  jq '.["group-apps"].value = false' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done

sudo apt install --reinstall -o Dpkg::Options::="--force-confmiss" grub2-theme-mint