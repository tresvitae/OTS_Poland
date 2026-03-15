# ==========================================
# Stage 1: Build TFS from source
# ==========================================
FROM alpine:3.19 AS build

RUN apk add --no-cache \
  binutils \
  boost-dev \
  build-base \
  cmake \
  crypto++-dev \
  fmt-dev \
  gcc \
  g++ \
  gmp-dev \
  luajit-dev \
  make \
  mariadb-connector-c-dev \
  pugixml-dev \
  git

COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt /usr/src/forgottenserver/

WORKDIR /usr/src/forgottenserver/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DSKIP_GIT=ON .. && make -j$(nproc)

# ==========================================
# Stage 2: Runtime image (minimal)
# ==========================================
FROM alpine:3.19

RUN apk add --no-cache \
  boost-date_time \
  boost-iostreams \
  boost-system \
  boost-filesystem \
  crypto++ \
  fmt \
  gmp \
  luajit \
  mariadb-connector-c \
  pugixml

COPY --from=build /usr/src/forgottenserver/build/tfs /bin/tfs
COPY data /srv/data/
COPY *.dist *.sql /srv/

EXPOSE 7171 7172
WORKDIR /srv
ENTRYPOINT ["/bin/tfs"]
