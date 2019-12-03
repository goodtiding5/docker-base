#!/bin/sh

set -e
set -u

# Run startup scripts

if [ -d /inittask ] && [ "$(ls /inittask/*.sh)" ]; then
  for init in /inittask/*.sh; do
    sh $init
  done
  # no need to run it again
  rm -f /inittask/*.sh
fi

# If we have an interactive container
if [[ -t 0 || -p /dev/stdin ]]; then
    export PS1='[\u@\h : \w]\$ '
  if [[ $@ ]]; then 
    eval "exec gosu ${AS_USER}:${AS_GROUP} $@"
  else 
    exec gosu ${AS_USER}:${AS_GROUP} /bin/sh
  fi

# If container is detached run superviord in the foreground 
else
  if [[ $@ ]]; then 
    eval "exec $@"
  else 
    exec /bin/sh
  fi
fi
