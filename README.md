# poeticjustice

Building a development PoeticJustice App Server
===============================================


The backend server for PoeticJustice is built using Pyaella.

[Pyaella](http://migacollabs.github.io/Pyaella/ "Pyaella Docs") .

Requirements
------------

- MacPorts
- Python 2.7.x
- PostgreSQL 9.2

Quickstart
----------

Install MacPorts!

Using MacPorts install Python 2.7

Using MacPorts install PostgreSQL 9.2

Start a PostgreSQL DB

	sudo /opt/local/etc/LaunchDaemons/org.macports.postgresql92-server/postgresql92-server.wrapper start


Create a `virtualenv` for PoeticJustice

	virtualenv --no-site-packages --distribute PoeticJusticeEnv


Change dir to PoeticJusticeEnv

	cd PoeticJusticeEnv


Switch to the virtualenv's Python

	source bin/activate


Get a Pyaella distribution

	...


Install the required numpy version

	pip install numpy==1.8.0


Install pillow

	pip install pillow


Install Pyaella into the virtualenv

	easy_install Pyaella[some version].egg


Check out the PoeticJustice git project

	git clone https://github.com/migacollabs/Poeticjustice.git


Change dir to PoeticJusticeEnv/Poeticjustice/poeticjustice


Install PoeticJustic database

	python -m pyaella.server.dbinstall -U postgres -O postgres --host localhost --port 5432 --contrib-dir /opt/local/share/postgresql92/contrib/postgis-2.0 --appcfg poeticjustice/appcfg.yaml --no-postgis --db poeticjustice


Start the app

	pserve development.ini

Note there are some environment variables that need to be set: PYTHONPATH, ASSETS_DIR, POETIC_JUSTICE_SMTP_SERVER, POETIC_JUSTICE_SMTP_USER, POETIC_JUSTICE_SMTP_PASSWORD
