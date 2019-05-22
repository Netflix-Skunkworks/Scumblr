#!/bin/bash

if [ $1 == "init" ]; then

    rake db:create
    rake db:structure:load

    for f in /docker-entrypoint-init.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.rb)     echo "$0: running $f"; rails r "$f"; echo ;;
            *)        echo "$0: ignoring $f" ;;
        esac
        echo
    done

fi

exec /usr/bin/supervisord -c /home/scumblr/supervisord.conf
