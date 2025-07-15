docker -run -d --name immich_machine_learning --gpus all -p 3003:3003 \
  -v $PWD/cache:/cache \
  immich-ml-jetson:latest
