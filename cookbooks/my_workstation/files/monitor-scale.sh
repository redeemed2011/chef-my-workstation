# Monitor Scale related.
sudo tee /etc/X11/xinit/xinitrc.d/70-xrandr-scale.sh <<'EOF' > /dev/null
#!/usr/bin/env sh

set -e
# Set the gnome scale to something larger than what we really want so we can scale it down.
gsettings set org.gnome.desktop.interface scaling-factor 2
# Get the name of the first connected display's port.
PRI_PORT="$(xrandr | grep -v disconnected | grep connected | cut -d' ' -f1)"
# Set the scale.
xrandr --output ${PRI_PORT} --scale 1.35x1.35
# Reset "panning" so xrandr will tell us the virtual resolution of the screen.
xrandr --output ${PRI_PORT} --panning 0x0
# Get the virtual resolution of the screen.
SCALED_RES="$(xrandr | grep ${PRI_PORT} | sed -E 's/.* ([0-9]+x[0-9]+).*/\1/')"
# Set the panning size to the virtual resolution of the screen to force it to properly fill the screen & avoid improper mou$
xrandr --output ${PRI_PORT} --panning ${SCALED_RES}
EOF

sudo chmod +x /etc/X11/xinit/xinitrc.d/70-xrandr-scale.sh
