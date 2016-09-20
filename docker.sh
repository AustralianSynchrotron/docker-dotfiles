DEFAULT_DOCKER_HOST=docker1
DEFAULT_VNC_PORT=5899

unalias docker &>/dev/null

function display_center ()
{
    columns="$(tput cols)";
    printf "%*s" $(( (${1} + columns) /2)) "$1" | tr ' ' -;
    printf "%*s\n" $(( (${1} + columns) / 2)) | tr ' ' -;
}


function __dockervnc {
  if [ -z "$1" ]; then
    docker ps;
  else
    VNCPORT=${2:-$DEFAULT_VNC_PORT}
    PORT=$(docker port $1 | grep $VNCPORT | awk '{print $3}' | cut -d":" -f 2)
    VNCPASSWD=$(docker inspect $1 | grep ASCI_ROOT_VNC_PASSWD | cut -d"\"" -f2 | cut -d"=" -f2)
    HOST=$(echo ${DOCKER_HOST:-127.0.0.1} | cut -d":" -f1)
    #echo "Opening $HOST:$PORT with $VNCPASSWD on $VNCPORT"
    open vnc://:$VNCPASSWD@$HOST:$PORT
  fi
}

function __dockerexec {
  if [ -z "$1" ]; then
    docker ps;
  else
    if docker exec -it $1 bash; then
      return
    else
      #echo "BASH not detected, trying with SH ..."
      docker exec -it $1 sh
    fi
  fi
}

function __dockerconnect {
  if [ -r ~/.docker/connect/$2 -a -n "$2" ]; then
    source ~/.docker/connect/$2
    export DOCKER_NAME="$(docker info 2>&1| grep Name | grep -v Pool | awk '{print $2}' | cut -d'.' -f1)"

    DOCKER_SWARM=$(docker info 2>&1 | grep "Swarm: " | cut -d' ' -f 2)
    if [ $DOCKER_SWARM = "active" ]; then
      DOCKER_NAME=$DOCKER_NAME"|S"
    fi
    else
      ls ~/.docker/connect/;
  fi
}

function __dockerwrapper {
  if [ "$1" = "connect" ]; then
      __dockerconnect $*
  else
    docker $*;
  fi
}

function __da {
  tput setaf 3;
  display_center Services;
  docker service ls;#| grep -v "REPLICAS";

  tput setaf 2;
  display_center Containers;
  docker ps ;#| grep -v "CONTAINER ID";

  tput setaf 4;
  display_center Images;
  docker images | grep -v "none";

  tput setaf 6;
  display_center Volumes;
  docker volume ls ;#| grep -v "VOLUME NAME";
}

# Docker wrapper command to catch new sub-command
alias docker='__dockerwrapper'

# Docker "exec" or "enter"
alias de='__dockerexec'

# Docker connect VNC (Mac only)
alias dvnc='__dockervnc'

# Print and follow container's log
alias dl='docker logs -f $1'

# List the docker services
alias ds='docker service ls'

# List the docker images
alias di='docker images | grep -v none'

# List the docker volumes
alias dv='docker volume ls'

# Short alias for docker command
alias d='docker'

# Short alias for docker-compose command
alias dc='docker-compose'

# Docker build and run in one command
alias db='docker build -t test . && docker run --rm -it test'

# Short alias for docker-machine command
alias dm='docker-machine'

# Temporary run an image
alias dr='docker run --rm -it $1'

# Remove all containers
alias drm='docker rm -f $(docker ps -aq)'

# Remove only dangling images
alias drmid='docker rmi $(docker images --quiet --filter "dangling=true")'

# Remove all images
alias drmi='docker rmi -f $(docker images -aq)'

# Remove all services
alias drms="docker service ls | grep -v REPLICAS | awk '{print $1}' | xargs docker service rm"

# Remove all volumes
alias drmv='docker volume rm $(docker volume ls -q)'

# Remove all containers and services
alias dclean='drms; drm;'

# Short alias for "docker connect"
alias dct="docker connect"

# Docker print all
alias da='PRINT=`__da`; echo "$PRINT"'

# Docker top to print all every second
alias dtop='while :; do PRINT=`__da`; echo "$PRINT" ; tput setaf 7; display_center | tr '-' '=';  sleep 1; done'

# Print the DOCKER current environment variables
alias dconn='env | grep DOCKER'

# Set the default docker host
docker connect $DEFAULT_DOCKER_HOST

# Set your prompt to display the $DOCKER_NAME env variable
