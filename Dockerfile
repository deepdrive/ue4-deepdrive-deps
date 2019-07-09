FROM adamrehn/ue4-full:4.21.2-cudagl10.0

# Ensure we are using a UTF-8 locale, as per the official TensorFlow Dockerfiles
ENV LANG C.UTF-8

# Install the TensorFlow dependencies not provided by the base image
# (Adapted from <https://github.com/tensorflow/tensorflow/blob/v1.13.1/tensorflow/tools/dockerfiles/dockerfiles/gpu.Dockerfile>)
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
	libcudnn7=7.4.1.5-1+cuda10.0 \
	libfreetype6-dev \
	libhdf5-serial-dev \
	libpng-dev \
	libzmq3-dev \
	nvinfer-runtime-trt-repo-ubuntu1804-5.0.2-ga-cuda10.0 \
	pkg-config && \
	apt-get update && apt-get install -y --no-install-recommends libnvinfer5=5.0.2-1+cuda10.0 && \
rm -rf /var/lib/apt/lists/*

# Install the GPU-enabled version of TensorFlow
RUN pip3 install tensorflow-gpu==1.13.1

# Install the dependencies for VirtualGL
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
	libfontconfig1 \
	libfreetype6 \
	libglu1 \
	libsm6 \
	libxcomposite1 \
	libxcursor1 \
	libxi6 \
	libxrandr2 \
	libxrender1 \
	libxss1 \
	libxv1 \
	x11-xkb-utils \
	xauth \
	xfonts-base \
	xkb-data && \
rm -rf /var/lib/apt/lists/*

# Install VirtualGL
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},display
ARG VIRTUALGL_VERSION=2.6.1
RUN cd /tmp && \
	curl -fsSL -O https://svwh.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
	dpkg -i *.deb && \
rm -f /tmp/*.deb

# Make sure the ue4-ci-helpers package is up to date
RUN pip3 install -U ue4-ci-helpers
USER ue4

# TEMPORARY: use our pre-bundled packaging script to install our dependency plugins
# (This will change once we've settled on the exact workflow for using this image)
COPY --chown=ue4:ue4 package.py /tmp/package.py
RUN python3 /tmp/package.py --plugins-only

# View https://simdocs.deepdrive.io/v/v3/docs/setup/linux/run-in-docker for usage
