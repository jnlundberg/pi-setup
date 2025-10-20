#!/bin/bash
set -e

echo "=== Uppdaterar systemet ==="
sudo apt update && sudo apt full-upgrade -y

echo "=== Grundläggande verktyg ==="
sudo apt install -y git curl vim htop build-essential unzip

echo "=== Tailscale ==="
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
echo "Kör 'sudo tailscale up' efter omstart för att logga in i ditt nätverk."

echo "=== Aktiverar SSH och VNC ==="
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

echo "=== Webbläsare: Firefox ESR ==="
sudo apt install -y firefox-esr gvfs-backends gvfs-fuse

echo "=== Kontorssvit ==="
sudo apt install -y libreoffice

echo "=== RetroPie ==="
cd ~
if [ ! -d RetroPie-Setup ]; then
  git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
fi
cd RetroPie-Setup
sudo ./retropie_setup.sh --all --quiet

echo "=== Installerar rclone för Google Drive ==="
sudo apt install -y rclone
mkdir -p ~/GoogleDrive

echo "=== Skapar autosync-script ==="
cat << 'EOF' > ~/sync_gdrive.sh
#!/bin/bash
rclone sync "gdrive:" ~/GoogleDrive --progress --drive-use-trash=false
EOF
chmod +x ~/sync_gdrive.sh

echo "=== Lägger till systemd-timer för automatisk synk var 30:e minut ==="
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

echo "=== Förbereder Pi-hole (valfritt) ==="
echo "Installera vid behov med:"
echo "  curl -sSL https://install.pi-hole.net | bash"

echo "=== Slut ==="
echo ""
echo "👉 Efter omstart:"
echo "1. Kör 'sudo tailscale up' för att koppla ihop Pi med nätverket."
echo "2. Kör 'rclone config' för att lägga till Google Drive (välj 'drive')."
echo "   Därefter synkas mappen ~/GoogleDrive automatiskt var 30:e minut."
echo "3. Starta RetroPie via menyn eller 'emulationstation'."
