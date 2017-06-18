## Overview

* Image based on alpine linux (currnetly 3.6)
* Contains mysql 11.1.22 (both client and server)
* When the image is first started mysql is automatically initialized
* MySQL runs as user nobody
* MySQL logs to standard output
* Very low footprint appx 170M


## Build This Image

```
docker build --network=host --tag alpine-mysql .
```


## Run the image

### Running for the first time (initialization)

You can pass the following environment variables to customize initialization

| Environment Variable | Default Value      | Description                              |
| -------------------- |--------------------| ---------------------------------------- |
| MYSQL_ROOT_PASSWORD  | randomly generated | Password for user root (db admin account)|
| MYSQL_DATABASE       | 'DB'               | Name of the database to create           |
| MYSQL_USER           | 'user'             | Username of the application user account |
| MYSQL_PASSWORD       | randomly generated | Password for the user MYSQL_USER         |
| PORT                 | 3306               | Port on which the DB should listen       |

* NOTE: Randomly generated passwords will be written to stdout so that you can copy paste them for later user
* User MYSQL_USER is automatically granted all permissions to database MYSQL_DATABASE
* Remote access is allowed for both root and MYSQL_USER via TCP (using the passwords provided)
* Anonymous/no password access is removed for all users.

```
docker run \
    -e MYSQL_ROOT_PASSWORD=my-root-pass \
    -e MYSQL_DATABASE=DATABASE \
    -e MYSQL_USER=mysql \
    -e MYSQL_PASSWORD=mysql-pass \
    -e PORT=1024 \
	-v /volume/MySql/data:/app/data \
	alpine-mysql	
```

### Running initialized DB

Once the database is initialized the above environment variables have no effect

So you can simply run your app as follows:

```
docker run \
	-v /volume/MySql/data:/app/data \
	alpine-mysql	
```

## Import data into initialized DB

Conveniently the image contains mysql client so you can use it to initialize the DB also.

Exec into the container

Run the command
```
mysql -u <username> -p<password> -h localhost --protocol=tcp DB </DATA_TO_IMPORT.sql
```

## Logging to SysLog

Docker supports logging of standard output to syslog.
Since the image is already logging to stdout simply start it as follows to run to syslog.

```
docker  --log-driver syslog \
    --name 'mysql' \
    --log-opt tag='{{.Name}}' \
	-v /volume/MySql/data:/app/data \
	alpine-mysql	
```

See docker documentation to customize log format using --log-opt 