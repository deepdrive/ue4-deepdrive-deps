FROM adamrehn/ue4-full:4.21.2-opengl

# Install the dependencies for VirtualGL
USER root
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

# In this version, we run the image by executing the following command in the root of the `deepdrive-sim` repo:
# ```
# docker run --rm -ti --runtime=nvidia -v`pwd`:/deepdrive-sim -w /deepdrive-sim -v/tmp/.X11-unix:/tmp/.X11-unix:rw -e DISPLAY deepdriveio/ue4-deepdrive-deps bash
# ```
# 
# We then build and run the Editor by executing the following commands in the container:
# ```
# ue4 build
# vglrun ue4 run
# ```
