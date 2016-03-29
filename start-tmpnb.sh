#!/bin/bash

# Start tmpnb service
export TOKEN=$( head -c 30 /dev/urandom | xxd -p )
docker run --net=host -d -e CONFIGPROXY_AUTH_TOKEN=$TOKEN --name=proxy jupyter/configurable-http-proxy --default-target http://127.0.0.1:9999
sleep 10
docker run -d \
    --net=host \
    -e CONFIGPROXY_AUTH_TOKEN=$TOKEN \
    -v /var/run/docker.sock:/docker.sock \
    jupyter/tmpnb \
    python orchestrate.py --image='iqss-jupyter-notebook' \
        --command='start-notebook.sh \
            "--NotebookApp.base_url={base_path} \
            --ip=0.0.0.0 \
            --port={port} \
            --NotebookApp.trust_xheaders=True"'


