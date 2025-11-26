FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    make \
    g++ \
    libsctp-dev \
    lksctp-tools \
    iproute2 \
    iputils-ping \
    && apt-get clean

# Copy UERANSIM binaries
COPY build /ueransim/build
COPY configs /ueransim/configs

WORKDIR /ueransim

CMD ["/bin/bash"]
