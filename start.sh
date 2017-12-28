#!/bin/ash

DATA_DIR=/app/data/mysql
SOCKET=/tmp/mysqld.sock


# Helper function for generating random password
random_password() {
	dd if=/dev/urandom bs=1 count=32 2>/dev/null | sha256sum | head -c 32
}

finish() {
   echo ">>> Terminating MYSQLD with pid $PID"
   kill $PID
}
trap finish 1 2 3 6 15

if [ ! -d ${DATA_DIR} ]; then
	echo ">>> Directory ${DATA_DIR} does not exist .... creating DB"
	mkdir ${DATA_DIR}
	
	echo ">>> Installing DB"
	mysql_install_db --user=nobody --datadir=${DATA_DIR}


  	if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
	    export MYSQL_ROOT_PASSWORD=`random_password`
	    echo ">>> MYSQL_ROOT_PASSWORD environment variable not specified ... generating random password"
	    echo ">>> Password for user root is ${MYSQL_ROOT_PASSWORD}"
  	fi

	if [ -z ${MSSQL_DATABASE} ]; then
	    export MYSQL_DATABASE='DB'
	    echo ">>> MYSQL_DATABASE environment variable not specified ... generating database 'DB'"
	fi

	if [ -z ${MYSQL_USER} ]; then
	    export MYSQL_USER='user'
	    echo ">>> MYSQL_USER environment variable not specified ... generating user 'user'"
	fi

	if [ -z ${MYSQL_PASSWORD} ]; then
		export MYSQL_PASSWORD=`random_password`
        echo ">>> MYSQL_PASSWORD environment variable not specified ... generating password"
	    echo ">>> Password for user ${MYSQL_USER} is ${MYSQL_PASSWORD}"
	fi


	/usr/bin/mysqld \
		--user=nobody \
		--datadir=${DATA_DIR} \
		--socket=${SOCKET} \
		--verbose=1 \
		--bootstrap  <<EOF
	USE mysql;
	FLUSH PRIVILEGES;
	GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
	GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

	-- Create DB
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8 COLLATE utf8_general_ci;

	-- Create user for DB
	GRANT ALL ON \`${MYSQL_DATABASE}\`.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

	-- Delete anonymous users
	DELETE FROM mysql.user WHERE user = '' or password = '';
	FLUSH PRIVILEGES;
EOF

	if [ $? -ne 0 ]; then
		echo ">>> Initialization of DB failed."
		exit 1
	fi

fi

if [ -z "${PORT}" ]; then
	echo ">>> PORT environment variable not specified ... using port 3306"
	export PORT=3306
fi

echo ">>>> Starting DB"
/usr/bin/mysqld \
	--user nobody \
	--datadir=${DATA_DIR} \
	--socket=${SOCKET} \
	--port ${PORT} \
	--log-warnings=1 \
	--log-error=/dev/stderr &
PID=$!
wait $PID
