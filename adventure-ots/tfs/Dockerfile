# ==========================================
# Stage 1: Build TFS from source (Ubuntu 22.04)
# Ubuntu 22.04 has libfmt 8.1.1 compatible with TFS 1.4.2
# ==========================================
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  cmake \
  g++ \
  make \
  libboost-date-time-dev \
  libboost-filesystem-dev \
  libboost-iostreams-dev \
  libboost-system-dev \
  libcrypto++-dev \
  libfmt-dev \
  libgmp-dev \
  libluajit-5.1-dev \
  libmariadb-dev \
  libmariadb-dev-compat \
  libpugixml-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt /usr/src/forgottenserver/

WORKDIR /usr/src/forgottenserver/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DSKIP_GIT=ON .. && make -j$(nproc)

# ==========================================
# Stage 2: Runtime image (minimal)
# ==========================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  libboost-date-time1.74.0 \
  libboost-filesystem1.74.0 \
  libboost-iostreams1.74.0 \
  libboost-system1.74.0 \
  libcrypto++8 \
  libfmt8 \
  libgmp10 \
  libluajit-5.1-2 \
  libmariadb3 \
  libpugixml1v5 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/src/forgottenserver/build/tfs /bin/tfs
COPY data /srv/data/
COPY *.dist *.sql /srv/

EXPOSE 7171 7172
WORKDIR /srv
ENTRYPOINT ["/bin/tfs"]
