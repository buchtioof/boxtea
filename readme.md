![grabber logo](./static/billboard.png)

# Boxtea - Simple Debian file administration

## About
Boxtea is a simple interface for file administration in a Debian server. Change Samba file configuration easily, give external users access to your Samba FS and check system status at a glance.\
*part of our internship period as SysAdmin, learn more about the project [in the docs notes (in french)](https://buchtioof.github.io/notes/projects/stage/main/)*

## Usage

Run the installer via this curl request:
`curl -sSL https://raw.githubusercontent.com/buchtioof/boxtea/main/run.sh | bash`

## Changelogs

### pre-releases

- v0.1: migrate from Grabber project
- v0.2: updating admin panel for BoxTea usage
- v0.3: Rework dashboard
- v0.4 and 0.5: bug fixes and functional state for dashboard
- v0.6: rework of the BoxTea usage, delete Docker to be local, work on the runner
- v0.7: refining runner to become an installer
- v0.8 (current): installer done
- v0.9 (soon): integrate Jarvis properly 

### releases

- v1: BoxTea standalone state with his installer, services via daemon and Jarvis integration.

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
