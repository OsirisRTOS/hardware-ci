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

RUN mkdir -p /actions-runner && \
	chmod 1777 /actions-runner

RUN useradd -m -s /bin/bash nonroot

RUN cd /actions-runner && \
	case $(uname -m) in \
	x86_64) ARCH="x64";; \
	aarch64) ARCH="arm64";; \
	*) echo "Unsupported architecture"; exit 1;; \
	esac && \
	RUNNER_URL=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".assets[] | .browser_download_url | select(. | test(\"actions-runner-linux-${ARCH}*\"))") && \
	curl -o actions-runner-linux-${ARCH}.tar.gz -L $RUNNER_URL && \
	tar xzf ./actions-runner-linux-${ARCH}.tar.gz && \
	rm actions-runner-linux-${ARCH}.tar.gz && \
	./bin/installdependencies.sh && \
	chown -R nonroot:nonroot /actions-runner

# Fix for Fedora not finding libstlink.so.1

RUN pip install PyYAML
COPY register-runner.py /actions-runner
RUN chmod +x /actions-runner/register-runner.py

ENV PATH="/actions-runner:${PATH}"

USER nonroot
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

WORKDIR /actions-runner

CMD [ "/actions-runner/register-runner.py" ]
