# syntax=docker/dockerfile:1

ARG CI_REGISTRY_IMAGE="default_ci_registry"
ARG TAG="default_tag"
ARG DOCKERFS_TYPE="default_dockerfs_type"
ARG DOCKERFS_VERSION="default_dockerfs_version"
ARG FREESURFER_VERSION="default_freesurfer_version"

# --- Stage 1: Freesurfer (big, heavy)
FROM ${CI_REGISTRY_IMAGE}/freesurfer:${FREESURFER_VERSION}${TAG} AS freesurfer

# --- Stage 2: Builder (only installs build deps + Python deps)
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG} AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG APP_NAME

WORKDIR /apps/${APP_NAME}

# Install build dependencies temporarily
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip python3 python3-dev build-essential python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies using BuildKit caching
COPY ./apps/${APP_NAME}/requirements.txt requirements.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -q -r requirements.txt

# Download RAMPS + SynthSeg sources
RUN wget -nv -O ramps.zip https://github.com/cnnp-lab/RAMPS/archive/refs/heads/main.zip \
    && unzip -qq ramps.zip -d /tmp \
    && mv /tmp/RAMPS-main RAMPS \
    && wget -nv -O synthseg.zip https://github.com/BBillot/SynthSeg/archive/refs/heads/master.zip \
    && unzip -qq synthseg.zip -d /tmp \
    && mkdir -p RAMPS/Place_SynthSeg_here/SynthSeg \
    && mv /tmp/SynthSeg-master/* RAMPS/Place_SynthSeg_here/SynthSeg \
    && rm ramps.zip synthseg.zip

# --- Stage 3: Final runtime image (clean, minimal)
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG}

LABEL maintainer="jonathan.haab@chuv.ch"

ARG APP_NAME
ARG APP_VERSION
ARG TAG
ARG PYTHON_VERSION=3.10

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

# Install only runtime deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python libs + sources from builder
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION}/dist-packages /usr/local/lib/python${PYTHON_VERSION}/dist-packages
COPY --from=builder /apps/${APP_NAME}/RAMPS ./RAMPS

# Copy only needed Freesurfer files (instead of full /usr/local/freesurfer if possible)
COPY --from=freesurfer /usr/local/freesurfer /usr/local/freesurfer

# Add aliases / ENV
RUN echo "alias ramps='python3 /apps/${APP_NAME}/RAMPS/RAMP.py'" > /etc/profile.d/ramps_alias.sh \
    && echo "export FREESURFER_HOME=/usr/local/freesurfer" > /etc/profile.d/freesurfer_home.sh

ENV APP_SPECIAL="terminal" \
    APP_CMD="" \
    PROCESS_NAME="" \
    APP_DATA_DIR_ARRAY="" \
    DATA_DIR_ARRAY=""

# Healthcheck
HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

# Copy scripts
COPY ./scripts/ scripts/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
