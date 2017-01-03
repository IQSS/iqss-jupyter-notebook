#!/bin/bash

# Start tmpnb service
export TOKEN=$( head -c 30 /dev/urandom | xxd -p )
sudo docker run --net=host -d -e CONFIGPROXY_AUTH_TOKEN=$TOKEN --name=proxy jupyter/configurable-http-proxy --default-target http://127.0.0.1:9999
sleep 10
sudo docker run -d \
    --net=host \
    -e CONFIGPROXY_AUTH_TOKEN=$TOKEN \
    -v /var/run/docker.sock:/docker.sock \
    jupyter/tmpnb \
    python orchestrate.py --image='iqss-jupyter-notebook' \
        --pool-size=30 \
        --cpu-quota=50000 \
        --mem-limit=1g \
        --command='start-notebook.sh \
            "--NotebookApp.base_url={base_path} \
            --ip=0.0.0.0 \
            --port={port} \
	    --NotebookApp.token=\"\" \
            --NotebookApp.trust_xheaders=True"'


