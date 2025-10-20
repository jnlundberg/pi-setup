#!/bin/bash
set -e

# ===================================
# Raspberry Pi 3B+ 32-bit install script
# RetroPie + Firefox + LibreOffice + rclone + Pi-hole prep
# Tailscale hoppas över på Pi 3B+ 32-bit
# ===================================

echo "=== Uppdaterar systemet ==="
sudo apt update && sudo apt full-upgrade -y

echo "=== Grundläggande verktyg ==="
sudo apt install -y git curl vim htop build-essential unzip

echo "=== SSH ==="
sudo raspi-config nonint do_ssh 0
sudo systemctl enable ssh

echo "=== Prestandaoptimering för Pi 3B+ ==="
sudo sed -i '/^gpu_mem=/d' /boot/config.txt
echo "gpu_mem=128" | sudo tee -a /boot/config.txt
# sudo sed -i '/CONF_SWAPSIZE=/d' /etc/dphys-swapfile
# echo "CONF_SWAPSIZE=1024" | sudo tee -a /etc/dphys-swapfile
# sudo systemctl restart dphys-swapfile

echo "=== Firefox ESR ==="
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

echo "=== Skapar systemd-timer för Google Drive-synk var 30:e minut ==="
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

echo "=== Pi-hole (valfritt) ==="
echo "Du kan installera Pi-hole senare med:"
echo "  curl -sSL https://install.pi-hole.net | bash"

echo "=== SLUT ==="
echo ""
echo "👉 Tailscale hoppar vi över på Pi 3B+ 32-bit."
echo "👉 Efter omstart:"
echo "1. Kör 'rclone config' för att logga in på Google Drive."
echo "2. Starta RetroPie via menyn eller 'emulationstation'."
