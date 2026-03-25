![grabber logo](./static/billboard.png)

# Boxtea - Simple Debian file administration

## About
Boxtea is a simple interface for file administration in a Debian server. Change Samba file configuration easily, give external users access to your Samba FS and check system status at a glance.\
*part of our internship period as SysAdmin, learn more about the project [in the docs notes (in french)](https://buchtioof.github.io/notes/projects/stage/main/)*

## Usage

### Docker deployment

Firstly, git clone this repo:\
`git clone https://github.com/buchtioof/boxtea.git`

In order to use properly your admin panel, create an .env file with these variables:\
```text
# Fill the blank spaces with your host IP, a username, an email and a password for admin user in order to use Grabber Admin.
# DO NOT USE ""

# SERVER SETTINGS
HOST=
PORT=8000

# ADMIN SETTINGS
DJANGO_SUPERUSER_USERNAME=
DJANGO_SUPERUSER_EMAIL=
DJANGO_SUPERUSER_PASSWORD=
```

Then, build the container with docker-compose:\
`docker-compose up -d --build`

Finally, access to your Grabber panel via the IP you've given in your .env file!

## Changelogs

### releases

- v0.1 (actual) : Non functional state, modification from Grabber to this project

## Contributing

In order to develop new features or work on the design, launch Grabber by using the docker-compose dedicated for development:
```
# enable HOT RELOADING and DEBUG in Django
docker-compose -f docker-compose.dev.yml up
```

## Dependencies (NEED TO BE UPDATED)

To run Grabber properly on your device, you will need these 3 dependencies available:
- [jq](https://github.com/jqlang/jq)
- [Python3](https://www.python.org/)
- [Sqlite3](https://sqlite.org/index.html)

Grabber will install automatically these 4 dependencies in python virtual environment:
- [Paramiko](https://www.paramiko.org/)
- [Django](https://www.djangoproject.com/)
- [Gunicorn](https://gunicorn.org/)
- [Whitenoise](https://github.com/evansd/whitenoise)

These 3 are already available in Grabber:
- [Alfred](https://github.com/buchtioof/alfred)
- [Tailwind](https://tailwindcss.com/)
- [Phosphor Icons](https://phosphoricons.com/)

# Credits
To the big work of all the dependencies used\
Image not mine
