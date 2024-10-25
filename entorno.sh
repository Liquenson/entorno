#!/bin/bash

###################################
# Borrar las maquinas y la red si existen
###################################

containers=("debian1" "debian2" "rocky1" "rocky2" "ubuntu1" "mysql1" "mysql2" "tomcat1" "tomcat2")
network_name="ansible"
subnet="172.18.0.0/16"

# Borrar contenedores si existen
for container in "${containers[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${container}\$"; then
        docker rm -f "$container" && echo "Eliminado contenedor $container"
    else
        echo "Contenedor $container no existe, se omite."
    fi
done

# Borrar red si existe
if docker network ls --format '{{.Name}}' | grep -Eq "^${network_name}\$"; then
    docker network rm "$network_name" && echo "Red $network_name eliminada"
else
    echo "Red $network_name no existe, se omite."
fi

###################################
# Crear la red
###################################
docker network create "$network_name" --subnet="$subnet" && echo "Red $network_name creada con subred $subnet."

###################################
# Crear y configurar las maquinas
###################################

docker_images=(
    "apasoft/debian11-ansible"
    "apasoft/debian11-ansible"
    "apasoft/rocky9-ansible"
    "apasoft/rocky9-ansible"
    "apasoft/ubuntu22-ansible"
    "apasoft/debian11-ansible"
    "apasoft/debian11-ansible"
    "apasoft/debian11-ansible"
    "apasoft/debian11-ansible"
)
ips=(
    "172.18.0.2"
    "172.18.0.3"
    "172.18.0.5"
    "172.18.0.6"
    "172.18.0.8"
    "172.18.0.10"
    "172.18.0.11"
    "172.18.0.12"
    "172.18.0.13"
)

# Crear contenedores con configuración específica
for i in "${!containers[@]}"; do
    docker run --detach --privileged \
        --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw \
        --ip "${ips[i]}" \
        --cgroupns=host \
        --name="${containers[i]}" \
        --network="$network_name" \
        "${docker_images[i]}" \
    && echo "Contenedor ${containers[i]} creado con IP ${ips[i]}"
done
