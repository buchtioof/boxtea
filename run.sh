#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
export LC_ALL=C
export LANG=C

##### MAIN VARIABLES #####
ALERT='\033[0;31m'      # RED
SUCCESS='\033[0;32m'    # GREEN
WARNING='\033[0;33m'    # YELLOW
ECM='\033[0m'           # END COLOR MESSAGE

BT_VERSION='0.1'
MOTOR_VERSION='NONE'

PROJECT_DIR=$(pwd)
CURRENT_USER=$USER
INSTALL_DIR="/opt/boxtea"
REPO_URL="https://github.com/buchtioof/boxtea.git"

##############################

######### USER SETUP ##########

setup_env() {
    echo -e "${WARNING}> No .env file found, let's configure your environment now.${ECM}"
    echo "---------- INTERNET CONFIGURATION ----------"
    echo "On which IP address you want to route BoxTea? (Leave blank to use the host IP)"
    read HOST < /dev/tty
    HOST=${HOST:-0.0.0.0}

    echo "Which port you want to use for BoxTea? (Leave blank to use 8000)"
    read PORT < /dev/tty
    PORT=${PORT:-8000}

    echo "---------- ADMIN CONFIGURATION ----------"
    echo "Now, create your superuser for the admin panel."
    echo "What username do you want to use? (Leave blank to use admin)"
    read SUNAME < /dev/tty
    SUNAME=${SUNAME:-admin}

    echo "Type the email address linked to this user."
    read MAIL < /dev/tty
    MAIL=${MAIL:-admin@boxtea.local}

    echo "Type the superuser password"
    while true; do
        read -s PASS < /dev/tty
        echo ""
            
        if [ -z "$PASS" ]; then
            # If password blank
            echo -e "${ALERT}> Password cannot be blank. Please type a valid password:${ECM}"
        elif [ ${#PASS} -lt 8 ]; then
            # If the password is less than 8 char
            echo -e "${ALERT}> Password must be at least 8 characters long. Please type again:${ECM}"
        else
            break
        fi
    done

    echo ""
    echo "Creating your environment file for BoxTea..."
    
    # Write secret key first then informations next
    echo "DJANGO_SECRET_KEY=$(openssl rand -base64 48)" >> "$INSTALL_DIR/.env"
    cat <<EOF > "$INSTALL_DIR/.env"
# SERVER SETTINGS
HOST=$HOST
PORT=$PORT

# ADMIN SETTINGS
DJANGO_SUPERUSER_USERNAME=$SUNAME
DJANGO_SUPERUSER_EMAIL=$MAIL
DJANGO_SUPERUSER_PASSWORD=$PASS
EOF

    echo -e "${SUCCESS}Configuration successful, BoxTea runner will continue the installation then.${ECM}"
}

##############################

########## MAIN ##########

main() {
    echo ""
    echo "1/8 Installation of the requirements..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq git python3 python3-venv python3-pip quota samba

    echo ""
    echo "2/8 Fetch the source code of BoxTea..."
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        sudo git clone -b feature/installer -q $REPO_URL $INSTALL_DIR
    else
        echo "> BoxTea alredy exists in installation folder, updating your current installation..."
        cd $INSTALL_DIR
        sudo git pull -q
    fi

    sudo chown -R $CURRENT_USER:www-data $INSTALL_DIR
    cd $INSTALL_DIR || exit

    echo ""
    echo "3/8 Configuration of the environment..."
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        setup_env
    fi

    export $(grep -v '^#' $INSTALL_DIR/.env | xargs)

    # Create if needed the data folder
    if [ ! -d "data" ]; then
        mkdir -p data
        sudo chown -R $CURRENT_USER:www-data data
    fi

    echo ""
    echo "4/8 Configuring the Python environment..."
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -r requirements.txt -q

    # Prepare DB
    echo ""
    echo "5/8 Checking database..."
    python manage.py makemigrations > /dev/null
    python manage.py migrate --noinput > /dev/null

    # Check for admin user
    echo ""
    echo -e "6/8 Creating the superuser..."
    if ! python ./lib/check_admin.py > /dev/null 2>&1; then

        if [[ -n "$DJANGO_SUPERUSER_USERNAME" && -n "$DJANGO_SUPERUSER_PASSWORD" ]]; then
            echo "Création de l'administrateur par défaut depuis le .env..."
            python manage.py createsuperuser --noinput > /dev/null 2>&1
        else
            echo -e "${ALERT}> No data found to create a superuser, please make sure your .env is correctly configured!${ECM}"
            exit
        fi
    else
        echo -e "${SUCCESS}> Administrateur déjà existant.${ECM}"
    fi

    # Place static files inside "staticfiles" Django folder
    echo "7/8 Prepare the static files for Django..."
    python manage.py collectstatic --noinput "input.css" > /dev/null 2>&1
    echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/sbin/useradd, /usr/sbin/chpasswd, /usr/bin/smbpasswd, /usr/sbin/setquota" | sudo tee /etc/sudoers.d/boxtea > /dev/null
    
    echo "Starting the server..."

    if ! grep -q "SESSION_TOKEN" "$INSTALL_DIR/.env"; then
        echo "SESSION_TOKEN=$(openssl rand -hex 32)" >> "$INSTALL_DIR/.env"
    fi

    sed -i '/BOXTEA_VERSION/d' "$INSTALL_DIR/.env"
    sed -i '/MOTOR_USED/d' "$INSTALL_DIR/.env"
    echo "BOXTEA_VERSION=$BT_VERSION" >> "$INSTALL_DIR/.env"
    echo "MOTOR_USED=$MOTOR_VERSION" >> "$INSTALL_DIR/.env"

   echo "8/8 Creating the service BoxTea..."
    cat <<EOF | sudo tee /etc/systemd/system/boxtea.service > /dev/null
[Unit]
Description=Boxtea server daemon for the admin panel
After=network.target

[Service]
User=$CURRENT_USER
Group=www-data
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/gunicorn --access-logfile - --workers 3 --bind $ADMIN_ADDRESS:$PORT config.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable boxtea > /dev/null 2>&1
    sudo systemctl restart boxtea

    echo ""
    echo -e "${SUCCESS}> BoxTea has been successfully installed in your machine!"
    echo "Access your admin panel with this address: http://$ADMIN_ADDRESS:$PORT"
}

##############################

########## BODY ##########
echo "               .-'''-.                                                        "
echo "             '   _    \                                                       "
echo "  /|       /   /   .   \                             __.....__                "
echo "  ||      .   |     \  '                         .-''         '.              "
echo "  ||      |   '      |  '                  .|   /     .-''¨'-.  .             "
echo "  ||  __  \    \     / /____     _____   .' |_ /     /________\   \    __     "
echo "  ||/'__ '. .   \ ..' / .   \  .'    / .'     ||                  | .:--.'.   "
echo "  |:/   '. '  '-...-'    \   \'    .' '--.  .-'\    .-------------'/ |   \ |  "
echo "  ||     | |               '.    .'      |  |   \    '-.____...---. ¨ __ | |  "
echo "  ||\    / '               .'     \.     |  |    \.             .'  .'.''| |  "
echo "  |/\'..' /              .'  .' .   \.   |  '.'    ¨''-...... -'   / /   | |_ "
echo "  '   --               .'   /    \.   \. |   /                     \ \._,\ '/ "
echo "                     '----'       '----' '-'                        --'       "      
echo ""
echo "Hello World! - Running BoxTea v$BT_VERSION"
echo ""
main
##############################