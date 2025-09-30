ARG CI_REGISTRY_IMAGE="default_ci_registry"
ARG TAG="default_tag"
ARG DOCKERFS_TYPE="default_dockerfs_type"
ARG DOCKERFS_VERSION="default_dockerfs_version"
ARG FREESURFER_VERSION="default_freesurfer_version"

FROM ${CI_REGISTRY_IMAGE}/freesurfer:${FREESURFER_VERSION}${TAG} AS freesurfer
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG}

LABEL maintainer="jonathan.haab@chuv.ch"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION
ARG TAG

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
    wget unzip python3 python3-dev build-essential python3-pip

COPY ./apps/${APP_NAME}/requirements.txt requirements.txt

RUN wget -O ramps.zip https://github.com/cnnp-lab/RAMPS/archive/refs/heads/main.zip && \
    unzip ramps.zip -d /tmp && \
    mkdir RAMPS &&  \
    mv /tmp/RAMPS-main/* RAMPS/ && \
    wget -O synthseg.zip https://github.com/BBillot/SynthSeg/archive/refs/heads/master.zip && \
    unzip synthseg.zip -d /tmp && \
    mkdir -p RAMPS/Place_SynthSeg_here/SynthSeg && \
    mv /tmp/SynthSeg-master/* RAMPS/Place_SynthSeg_here/SynthSeg && \
    rm ramps.zip && rm synthseg.zip && \
    pip install -r requirements.txt && \
    echo "export FREESURFER_HOME=/usr/local/freesurfer" > /etc/profile.d/freesurfer_home.sh

RUN apt-get remove -y --purge wget unzip python3-dev build-essential python3-pip && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#Freesurfer
COPY --from=freesurfer /usr/local/freesurfer /usr/local/freesurfer

ENV APP_SPECIAL="terminal"
ENV APP_CMD=""
ENV PROCESS_NAME=""
ENV APP_DATA_DIR_ARRAY=""
ENV DATA_DIR_ARRAY=""

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/
ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
