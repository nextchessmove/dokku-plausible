# dokku-plausible

This is an example of how run plausible on dokku.

## Setup

First create the plausible application:

    $ dokku apps:create plausible

Plausible needs a postgresql and a clickhouse database.  Dokku has official
plugins for both.  Install the plugins:

    $ sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
    $ sudo dokku plugin:install https://github.com/dokku/dokku-clickhouse.git clickhouse

Create the postgresql database and link it to the plausible app:

    $ dokku postgres:create plausible
    $ dokku postgres:link plausible plausible

Create the clickhouse database and link it to the plausible app:

    $ dokku clickhouse:create plausible
    $ dokku clickhouse:link plausible plausible

# General Plausible Configuration

Set the plausible admin user credentials:

    $ dokku config:set plausible ADMIN_USER_EMAIL=admin@example.com
    $ dokku config:set plausible ADMIN_USER_NAME=admin
    $ dokku config:set plausible ADMIN_USER_PWD=secret

Set the base URL, i.e., the URL plausible will be hosted from:

    $ dokku config:set plausible BASE_URL=http://plausible.example.com/

Set the secret key base.  It should be long (at least 64 characters) and
random.  If you have Phoenix installed, you can generate this with `mix
phx.gen.secret`.  Otherwise you can use openssl to generate some random bytes
and base64 encode it:

    $ dokku config:set plausible SECRET_KEY_BASE=$(openssl rand 60 | base64 -w 0)

# SMTP Configuration

Plausible needs a SMTP server to send emails.  I'm using SES.  Substitute your
own values:

    $ dokku config:set plausible MAILER_EMAIL=sender@example.com --no-restart
    $ dokku config:set plausible SMTP_HOST_ADDR=email-smtp.us-west-2.amazonaws.com
    $ dokku config:set plausible SMTP_HOST_PORT=587
    $ dokku config:set plausible SMTP_USER_NAME=your_smtp_user_name
    $ dokku config:set plausible SMTP_USER_PWD=your_smtp_user_password

# Understand this Dockerfile

Before deploying, take a look at the Dockerfile in this repository to
understand what's going on.

When you link the plausible clickhouse database to the plausible application,
dokku makes some environment variables available inside of your plausible
container.  One is called `CLICKHOUSE_URL`:

    CLICKHOUSE_URL=clickhouse://plausible:3e1dd262671f044e@dokku-clickhouse-plausible:9000/plausible

However that's not exactly what we want for two reasons:

  1. Plausible is expecting an environment variable called
     `CLICKHOUSE_DATABASE_URL`, and
  2. The URL is for port 9000 which is for the clickhouse native TCP interface
     and plausible expects to connect to clickhouse's HTTP interface running on
     port 8123.

Fortunately the dokku clickhouse plugin adds some other environment variables
which we can use to construct the URL that plausible expects:

    DOKKU_CLICKHOUSE_PLAUSIBLE_ENV_CLICKHOUSE_DB=plausible
    DOKKU_CLICKHOUSE_PLAUSIBLE_ENV_CLICKHOUSE_PASSWORD=3e1dd262671f044e
    DOKKU_CLICKHOUSE_PLAUSIBLE_PORT_8123_TCP_ADDR=172.17.0.4
    DOKKU_CLICKHOUSE_PLAUSIBLE_PORT_8123_TCP_PORT=8123
    DOKKU_CLICKHOUSE_PLAUSIBLE_ENV_CLICKHOUSE_DB=plausible

The Dockerfile in this project uses these to export the
`CLICKHOUSE_DATABASE_URL` environment variable which plausible uses to connect
to the database.

# Deploy

Clone this repository, add a remote pointing to your dokku server, and push:

    $ git clone https://github.com/nextchessmove/dokku-plausible.git
    $ cd dokku-plausible
    $ git remote add dokku dokku@example.com:plausible
    $ git push dokku master

With that, plausible should be up and running having everything it needs to
connect to the postgresql database, the clickhouse database, and the SMTP
server.


# IP Geolocation

You'll need an account ID and license key from MaxMind.  Once you have those,
create a maxmind app to periodically download the maxmind country database: 

    $ dokku apps:create maxmind

Configure it:

    $ dokku config:set maxmind GEOIPUPDATE_ACCOUNT_ID=<account_id>
    $ dokku config:set maxmind GEOIPUPDATE_LICENSE_KEY=<license_key>
    $ dokku config:set maxmind GEOIPUPDATE_FREQUENCY=168
    $ dokku config:set maxmind GEOIPUPDATE_EDITION_IDS=GeoLite2-Country

As root, create a shared mount point to share the MaxMind country database:

    # cd /var/lib/dokku/data/storage
    # mkdir maxmind
    # sudo chown -R 32767:32767 maxmind

Mount it in the filesystem where the container downloads the database:

    $ dokku storage:mount maxmind /var/lib/dokku/data/storage/maxmind:/usr/share/GeoIP

Install the container:  (Requires dokku 0.24)

    $ dokku git:from-image maxmind maxmindinc/geoipupdate

Mount the same directory in the plausible container:

    $ dokku storage:mount plausible /var/lib/dokku/data/storage/maxmind:/geoip

Finally, configure plausible to use the country database:

    $ dokku config:set plausible GEOLITE2_COUNTRY_DB=/geoip/GeoLite2-Country.mmdb
