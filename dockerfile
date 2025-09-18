# ========================== #
#     FFMPEG STREAM REC    #
# ========================== #

# --------- Builder Stage ---------
FROM debian:bookworm-slim AS builder

ARG FFMPEG_VERSION=n7.0.2

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get -qq install --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        yasm \
        ca-certificates \
        libsrt-gnutls-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/FFmpeg/FFmpeg.git \
        --depth 1 \
        --branch "${FFMPEG_VERSION}" \
        --single-branch \
        /FFmpeg-${FFMPEG_VERSION}

WORKDIR /FFmpeg-${FFMPEG_VERSION}

RUN ./configure \
    --prefix="/usr/local" \
    --disable-doc \
    --disable-htmlpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-ffprobe \
    --disable-ffplay \
    --disable-debug \
    --disable-autodetect \
    --enable-ffmpeg \
    --enable-protocol=file \
    --enable-protocol=rtp \
    --enable-protocol=udp \
    --enable-protocol=tcp \
    --enable-protocol=srt \
    --enable-demuxer=mpegts \
    --enable-demuxer=rtp \
    --enable-muxer=mp4 \
    --enable-muxer=segment \
    --enable-libsrt \
    --enable-small \
    && make -j"$(nproc)" \
    && make install \
    && strip /usr/local/bin/ffmpeg

# --------- Runtime Stage ---------
FROM debian:bookworm-slim AS runtime

LABEL maintainer="dogu-yalcinkaya" \
      description="FFmpeg streaming segmentation container" \
      version="1.0"

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get -qq update; \
    apt-get -qq install --no-install-recommends bash ca-certificates; \
    pkg="$(apt-cache search '^libsrt1\..*-gnutls$' | awk '{print $1}' | sort -r | head -n1)"; \
    test -n "$pkg"; \
    apt-get -qq install --no-install-recommends "$pkg"; \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r ffmpeg && useradd -r -g ffmpeg -s /bin/bash ffmpeg

COPY --from=builder /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /output && chown -R ffmpeg:ffmpeg /output

USER ffmpeg
WORKDIR /output

ENV SEGMENT_TIME=1800 \
    OUTPUT_DIR=/output \
    LOGLEVEL=info

VOLUME ["/output"]

HEALTHCHECK --interval=60s --timeout=30s --start-period=20s --retries=3 \
    CMD test -d /output || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]