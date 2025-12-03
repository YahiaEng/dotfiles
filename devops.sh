# -------
# Essentials
# -------
sudo pacman -S github-cli

# -------
# Docker
# -------
sudo pacman -S docker docker-compose
sudo systemctl start docker.socket
sudo systemctl enable docker.socket
sudo usermod -aG docker $USER
docker -v

# ---------
# Terraform
# ---------
sudo paru -S terrafrom diffutils

sudo paru -S go

terraform -v