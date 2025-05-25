FROM ghcr.io/osirisrtos/osiris/devcontainer:feature-reduce-container-size


RUN dnf update -y && \
	dnf install -y --setopt=keepcache=0 \
	python3 \
	python3-pip \
	jq

RUN mkdir -p /actions-runner

RUN cd /actions-runner && \
	case $(uname -m) in \
	x86_64) ARCH="x64";; \
	aarch64) ARCH="arm64";; \
	*) echo "Unsupported architecture"; exit 1;; \
	esac && \
	RUNNER_URL=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".assets[] | .browser_download_url | select(. | test(\"actions-runner-linux-${ARCH}*\"))") && \
	curl -o actions-runner-linux-${ARCH}.tar.gz -L $RUNNER_URL && \
	sudo tar xzf ./actions-runner-linux-${ARCH}.tar.gz && \
	rm actions-runner-linux-${ARCH}.tar.gz && \
	./bin/installdependencies.sh

RUN pip install PyYAML
COPY board_info register_runner.py /actions-runner/
RUN chmod +x /actions-runner/register_runner.py /actions-runner/board_info

ENV PATH="/actions-runner:${PATH}"

WORKDIR /actions-runner

ENTRYPOINT [ "/actions-runner/register_runner.py" ]
