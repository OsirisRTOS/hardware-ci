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


RUN mkdir /actions-runner && cd /actions-runner && \
	case $(uname -m) in \
	x86_64) ARCH="x64";; \
	aarch64) ARCH="arm64";; \
	*) echo "Unsupported architecture"; exit 1;; \
	esac && \
	RUNNER_URL=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".assets[] | .browser_download_url | select(. | test(\"actions-runner-linux-${ARCH}*\"))") && \
	curl -o actions-runner-linux-${ARCH}.tar.gz -L $RUNNER_URL && \
	tar xzf ./actions-runner-linux-${ARCH}.tar.gz && \
	rm actions-runner-linux-${ARCH}.tar.gz

ENV PATH="/actions-runner:${PATH}"

USER nonroot

ENTRYPOINT ["/bin/bash"]
