#!/bin/bash

###################################
# Borrar las maquinas y la red si existen
###################################

containers=("web1" "web2" "db1" "db2" "cache1" "cache2")
network_name="mynetwork"
subnet="192.168.1.0/24"

# Borrar contenedores si existen
for container in "${containers[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}\$"; then
        if docker rm -f "$container"; then
            echo "Eliminado contenedor $container"
        else
            echo "Error al eliminar contenedor $container"
        fi
    else
        echo "Contenedor $container no existe, se omite."
    fi
done

# Borrar red si existe
if docker network ls --format '{{.Name}}' | grep -q "^${network_name}\$"; then
    if docker network rm "$network_name"; then
        echo "Red $network_name eliminada"
    else
        echo "Error al eliminar red $network_name"
    fi
else
    echo "Red $network_name no existe, se omite."
fi

###################################
# Crear la red
###################################
if docker network create "$network_name" --subnet="$subnet"; then
    echo "Red $network_name creada con subred $subnet."
else
    echo "Error al crear la red $network_name"
fi

###################################
# Crear y configurar las maquinas
###################################

docker_images=(
    "nginx:latest"       # Imagen para web1
    "nginx:latest"       # Imagen para web2
    "mysql:5.7"          # Imagen para db1
    "mysql:5.7"          # Imagen para db2
    "redis:alpine"       # Imagen para cache1
    "redis:alpine"       # Imagen para cache2
)

ips=(
    "192.168.1.10"
    "192.168.1.11"
    "192.168.1.20"
    "192.168.1.21"
    "192.168.1.30"
    "192.168.1.31"
)

# Crear contenedores con configuración específica
for i in "${!containers[@]}"; do
    if docker run --detach --privileged \
        --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw \
        --ip "${ips[i]}" \
        --cgroupns=host \
        --name="${containers[i]}" \
        --network="$network_name" \
        "${docker_images[i]}"; then
        echo "Contenedor ${containers[i]} creado con IP ${ips[i]}"
    else
        echo "Error al crear contenedor ${containers[i]}"
    fi
done
