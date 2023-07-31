ARG BASE_IMAGE
FROM ${BASE_IMAGE} as build

# Move into a project directory and copy in all required files (using .dockerignore)
COPY .. /app/

# Install python requirements from Pipfile and Pipfile.lock
RUN set -ex && pip install pipenv
RUN PIP_NO_CACHE_DIR=0 PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

RUN printf '#!/usr/bin/env bash  \n\
source /app/.venv/bin/activate   \n\
exec python /app/main.py "$@" \
' >> /app/entrypoint.sh

RUN chmod 700 entrypoint.sh
ENTRYPOINT [ "/app/entrypoint.sh" ]

