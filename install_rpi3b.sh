#!/bin/bash
set -e

echo "=== Uppdaterar systemet ==="
sudo apt update && sudo apt full-upgrade -y

echo "=== Grundläggande verktyg ==="
sudo apt install -y git curl vim htop build-essential unzip

echo "=== SSH och VNC ==="
sudo raspi-config nonint do_ssh 0
sudo raspi-config nonint do_vnc 0
sudo systemctl enable ssh
sudo systemctl enable vncserver-x11-serviced

echo "=== Prestandaoptimering för Pi 3B+ ==="
sudo sed -i '/^gpu_mem=/d' /boot/config.txt
echo "gpu_mem=128" | sudo tee -a /boot/config.txt
sudo sed -i '/CONF_SWAPSIZE=/d' /etc/dphys-swapfile
echo "CONF_SWAPSIZE=1024" | sudo tee -a /etc/dphys-swapfile
sudo systemctl restart dphys-swapfile

echo "=== Firefox ESR (snabbare än Chromium på Pi 3B+) ==="
sudo apt install -y firefox-esr gvfs-backends gvfs-fuse

echo "=== LibreOffice ==="
sudo apt install -y libreoffice

echo "=== RetroPie ==="
cd ~
if [ ! -d RetroPie-Setup ]; then
  git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
fi
cd RetroPie-Setup
sudo ./retropie_setup.sh --all --quiet

echo "=== rclone för Google Drive ==="
sudo apt install -y rclone
mkdir -p ~/GoogleDrive

echo "=== Skapar autosync-script ==="
cat << 'EOF' > ~/sync_gdrive.sh
#!/bin/bash
rclone sync "gdrive:" ~/GoogleDrive --progress --drive-use-trash=false
EOF
chmod +x ~/sync_gdrive.sh

echo "=== systemd-timer för automatisk Google Drive-synk ==="
cat << 'EOF' | sudo tee /etc/systemd/system/gdrive-sync.service > /dev/null
[Unit]
Description=Sync Google Drive to local folder

[Service]
Type=oneshot
ExecStart=/home/pi/sync_gdrive.sh
User=pi
EOF

cat << 'EOF' | sudo tee /etc/systemd/system/gdrive-sync.timer > /dev/null
[Unit]
Description=Run Google Drive sync every 30 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=30min
Unit=gdrive-sync.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl enable gdrive-sync.timer
sudo systemctl start gdrive-sync.timer

echo "=== Pi-hole förberett (installera senare om du vill) ==="
echo "Installera vid behov med:"
echo "  curl -sSL https://install.pi-hole.net | bash"

echo "=== SLUT ==="
echo ""
echo "👉 Tailscale hoppar vi över på Pi 3B+ 32-bit."
echo "👉 Efter omstart kan du:"
echo "   1. Logga in på Google Drive med 'rclone config'."
echo "   2. Starta RetroPie via menyn eller 'emulationstation'."
