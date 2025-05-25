FROM ghcr.io/osirisrtos/osiris/devcontainer:feature-reduce-container-size

# Create a non-root user and group with the same UID/GID as the host user
ARG USERNAME=runner
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME && \
	useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# Install required packages
RUN dnf update -y && \
	dnf install -y --setopt=keepcache=0 \
	python3 \
	python3-pip \
	jq && \
	dnf clean all

# Switch to the non-root user
USER $USERNAME

# Create the actions-runner directory
RUN mkdir -p /home/$USERNAME/actions-runner

# Download and set up the GitHub Actions Runner
RUN cd /home/$USERNAME/actions-runner && \
	case $(uname -m) in \
	x86_64) ARCH="x64";; \
	aarch64) ARCH="arm64";; \
	*) echo "Unsupported architecture"; exit 1;; \
	esac && \
	RUNNER_URL=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".assets[] | .browser_download_url | select(. | test(\"actions-runner-linux-${ARCH}*\"))") && \
	curl -o actions-runner-linux-${ARCH}.tar.gz -L $RUNNER_URL && \
	tar xzf ./actions-runner-linux-${ARCH}.tar.gz && \
	rm actions-runner-linux-${ARCH}.tar.gz

USER root
RUN cd /home/$USERNAME/actions-runner && \
	./bin/installdependencies.sh
USER $USERNAME

# Install Python dependencies
RUN pip install --user PyYAML requests

# Copy necessary files
COPY board_info register_runner.py /home/$USERNAME/actions-runner/
USER root
RUN chmod +x /home/$USERNAME/actions-runner/register_runner.py /home/$USERNAME/actions-runner/board_info
USER $USERNAME

# Update PATH for the non-root user
ENV PATH="/home/$USERNAME/actions-runner:${PATH}"

# Set the working directory
WORKDIR /home/$USERNAME/actions-runner

# Set the entrypoint
ENTRYPOINT [ "/home/runner/actions-runner/register_runner.py" ]
