#!/bin/bash

# Define application lists for Ubuntu and AMI
UBUNTU_APPLICATION_LIST=(
  "nodejs"
  "postgresql"
  "apache2"
)

AMI_APPLICATION_LIST=(
  "nodejs"
  "postgresql15.x86_64"
  "postgresql15-server"
  "httpd"
)

# Function to install applications
install_applications() {
  local package_manager=$1
  local application_list=("${@:2}")

  echo "Installing necessary applications..."

  for app in "${application_list[@]}"; do
    echo "Installing $app..."
    case $package_manager in
      apt)
        sudo apt-get update
        sudo apt-get install -y "$app"
        ;;
      dnf)
        sudo dnf -y update
        sudo dnf -y install "$app"
        ;;
    esac

    if [ $? -ne 0 ]; then
      echo "Exit Code ($?): An error occurred during installation of $app"
      exit $?
    fi
  done
}

# Function to daemonize the system
daemonize_system() {
  echo "Daemonizing the system..."

  if rpm -qa | grep httpd; then
    echo "Starting httpd daemon..."
    sudo systemctl enable httpd
    sudo systemctl start httpd
    sudo systemctl status httpd
  elif dpkg -l apache2 > /dev/null 2>&1; then
    echo "Starting apache2 daemon..."
    sudo systemctl enable apache2
    sudo systemctl start apache2
    sudo systemctl status apache2
  fi

  # Setup postgreSQL
  sudo systemctl enable postgresql
  sudo systemctl start postgresql

  if [ $? -ne 0 ]; then
    echo "An error occurred while enabling postgres daemon"
  fi

  sudo postgresql-setup --initdb
}

# Function to set up postgreSQL password
setup_postgresql_password() {
  echo "Enter your password for 'postgres' user: "
  read -r password

  if [ -z "$password" ]; then
    echo "Please enter a correct password"
  else
    sudo passwd postgres "$password"
    echo "Perfect! Password set successfully!"
  fi

  echo "Enter password for postgres database:"
  read -r dbPassword

  sudo -u postgres psql -c "ALTER ROLE postgres WITH PASSWORD '$dbPassword'"

  if [ $? -ne 0 ]; then
    echo "Failed to set up the password for postgres user"
  fi
}

# Main script
if command -v apt &> /dev/null; then
  install_applications apt "${UBUNTU_APPLICATION_LIST[@]}"
elif command -v dnf &> /dev/null; then
  install_applications dnf "${AMI_APPLICATION_LIST[@]}"
fi

daemonize_system
setup_postgresql_password

echo "Enjoy! Everything set up perfectly!"
