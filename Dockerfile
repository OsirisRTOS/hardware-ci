FROM fedora:latest AS devcontainer

RUN dnf update -y && \
	dnf install -y --setopt=keepcache=0 \
	@development-tools \
	git \
	cmake \
	make \
	libusb1-devel \
	python3 \
	python3-pip \
	jq

RUN git clone --single-branch --depth 1 -b "develop" https://github.com/stlink-org/stlink.git /tmp/stlink && \
	cd /tmp/stlink && \
	make -j release && \
	make install && \
	ldconfig && \
	rm -rf /tmp/stlink

USER nonroot

ENTRYPOINT ["/bin/bash"]
