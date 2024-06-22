FROM rastasheep/ubuntu-sshd:18.04

# Environment variables
ARG USER=224b3f18-5efc-4a5f-86d9-a797673410b8
ARG UID=1000
ARG GID=1000

# Install necessary packages and create the user
RUN apt-get update && apt-get install -y sudo && \
    groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER} && \
    mkdir -p /home/${USER}/.ssh && \
    chown -R ${USER}:${USER} /home/${USER}

# Add sshd configuration
COPY ./sshd_config /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
