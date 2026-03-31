#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
export LC_ALL=C
export LANG=C

##### MAIN VARIABLES #####
ALERT='\033[0;31m'      # RED
SUCCESS='\033[0;32m'    # GREEN
WARNING='\033[0;33m'    # YELLOW
ECM='\033[0m'           # END COLOR MESSAGE

BT_VERSION='0.0.5-alpha'
MOTOR_VERSION='NONE'

PROJECT_DIR=$(pwd)
CURRENT_USER=$USER
INSTALL_DIR="/opt/boxtea"
REPO_URL="https://github.com/buchtioof/boxtea.git"

##############################

######### ELEMENTS ##########

setup_env() {
    echo -e "${WARNING}> No .env file found, let's configure your environment now.${ECM}"
    echo "---------- INTERNET CONFIGURATION ----------"
    echo "On which IP address you want to route BoxTea? (Leave blank to use the host IP)"
    read HOST
    HOST=${HOST:-0.0.0.0}

    echo "Which port you want to use for BoxTea? (Leave blank to use 8000)"
    read PORT
    PORT=${PORT:-8000}

    echo "---------- ADMIN CONFIGURATION ----------"
    echo "Now, create your superuser for the admin panel."
    echo "What username do you want to use? (Leave blank to use admin)"
    read SUNAME
    SUNAME=${SUNAME:-admin}

    echo "Type the email address linked to this user."
    read MAIL
    MAIL=${MAIL:-admin@boxtea.local}

    echo "Type the superuser password"
    while true; do
        read -s PASS
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

    cat <<EOF > "$PROJECT_DIR/.env"
# SERVER SETTINGS
HOST=$HOST
PORT=$PORT

# ADMIN SETTINGS
DJANGO_SUPERUSER_USERNAME=$SUNAME
DJANGO_SUPERUSER_EMAIL=$MAIL
DJANGO_SUPERUSER_PASSWORD=$PASS
EOF

    echo -e "${SUCCESS}Configuration successful, BoxTea runner will continue the installation then."
}

##############################

########## MAIN ##########

main() {
    echo "1/8 Installation of the requirements..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq git python3 python3-venv python3-pip quota samba

    echo "2/8 Fetch the source code of BoxTea...${ECM}"
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        sudo git clone -q $GIT_REPO_URL $INSTALL_DIR
    else
        echo "> BoxTea alredy exists in installation folder, updating your current installation..."
        cd $INSTALL_DIR
        sudo git pull -q
    fi

    sudo chown -R $CURRENT_USER:www-data $INSTALL_DIR
    cd $INSTALL_DIR || exit

    echo "3/8 Configuration of the environment..."
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        setup_env
    fi

    # Create if needed the data folder
    if [ ! -d "./data" ]; then
        mkdir -p data
    fi

    # Generate session token and save in a variable
    export SESSION_TOKEN=$(openssl rand -hex 32)

    # Prepare DB
    echo "Checking database..."
    python manage.py makemigrations > /dev/null
    python manage.py migrate --noinput > /dev/null

    # Check for admin user
    echo "Checking Admin existence..."
    if ! python ./lib/check_admin.py > /dev/null 2>&1; then

        if [[ -n "$DJANGO_SUPERUSER_USERNAME" && -n "$DJANGO_SUPERUSER_PASSWORD" ]]; then
            echo "Creating default admin from .env variables..."
            python manage.py createsuperuser --noinput > /dev/null 2>&1 || echo -e "${WARNING}> Failed to create admin. Password might be too common.${ECM}"
        else
            echo -e "${WARNING}> No Superuser detected and no credentials found in .env!${ECM}"
            echo -e "${WARNING}> To create one later, run: docker exec -it grabber-prod python manage.py createsuperuser${ECM}"
        fi
    else
        echo -e "${WARNING}> Done!${ECM}"
    fi

    # Place static files inside "staticfiles" Django folder
    echo "Collecting static files..."
    python manage.py collectstatic --noinput --ignore "input.css" > /dev/null
    
    echo "Starting the server..."
    export DJANGO_ALLOWED_HOST=$ADMIN_ADDRESS

    # Change by the version 
    export BOXTEA_VERSION=$BT_VERSION
    export MOTOR_USED=$MOTOR_VERSION

    # Check if user added settings
    if [[ -z "$ADMIN_ADDRESS" || "$ADMIN_ADDRESS" == "null" ]]; then 
        echo -e "${WARNING}> No Address set in settings.json, address "localhost" is chosen${ECM}"
    fi
    sleep 1
    if [[ -z "$PORT" || "$PORT" == "null" ]]; then 
        echo -e "${WARNING}> No Address set in settings.json, port "8000" is chosen${ECM}";
    fi

    sleep 2

    # Run server for each purpose
    if [ "$DEBUG" = "True" ]; then
        echo "Start the dev server"
        exec python manage.py runserver 0.0.0.0:$PORT
    else
        echo "Start the production server"
        gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 3 --access-logfile - &
    fi
    
    SERVER_PID=$!

    trap cleanup INT

    echo ""
    echo -e "${SUCCESS}> Dashboard launched at http://$ADMIN_ADDRESS:$PORT${ECM}"
    echo ""
    echo "[SERVER LOGS]"

    wait $SERVER_PID
}

##############################

########## USER INTERACTION ##########
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