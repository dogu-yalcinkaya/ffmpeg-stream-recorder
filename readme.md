# FFmpeg Stream Recorder with Docker

This project provides a simple, containerized way to record various media streams with FFmpeg and to serve the resulting recordings via a web server.

Below are example Docker commands for recording streams with FFmpeg and making the recordings easily accessible. Although the examples focus on SRT, they also apply to other FFmpeg-supported inputs (e.g., RTMP, RTSP, RTP over UDP, HLS over HTTP/HTTPS), with protocol-specific URLs and options as needed.

## FFmpeg build requirements

Make sure your FFmpeg build includes the required protocols, demuxers, and (if needed) TLS libraries.

Commonly useful configure flags:
```bash
--enable-libsrt \
--enable-librist \
--enable-openssl   # or --enable-gnutls or --enable-mbedtls
# optionally:
# --enable-librtmp
```

If you prefer enabling specific protocols/demuxers explicitly:
```bash
--enable-protocol=rtp \
--enable-protocol=udp \
--enable-protocol=tcp \
--enable-protocol=srt \
--enable-demuxer=mpegts
```

## 1) Raw FFmpeg command example

This is the core `ffmpeg` command used for recording. The Docker container wraps this logic.

```bash
ffmpeg -i srt://localhost:5421?mode=caller \
  -c copy \
  -f segment -segment_time 180 \
  -reset_timestamps 1 -strftime 1 \
  ut_%Y%m%d_%H%M.mp4
```

Replace the input URL with your desired protocol/stream as needed.


## 2) Build the Docker image

First, build the Docker image for the stream recorder.

Standard build:
```bash
docker build --build-arg FFMPEG_VERSION=n7.0.2 -t ffmpeg-stream-recorder .
```

No-cache build:
```bash
docker build --no-cache --build-arg FFMPEG_VERSION=n7.0.2 -t ffmpeg-stream-recorder .
```


## 3) Create a Docker volume

Create a Docker volume to store the recordings persistently:

```bash
docker volume create recordings-volume
```


## 4) Run the stream recorder container

Run one or more recorder containers. You can change `INPUT_URL` to use any supported input (e.g., `srt://`, `rtmp://`, `rtsp://`, `rtp://`, `udp://`, or `https://` for HLS playlists).

```bash
docker run -d \
  --name channel-one \
  --hostname channel-one \
  -e INPUT_URL="srt://localhost:5421?mode=caller" \
  -e SEGMENT_TIME=180 \
  -v recordings-volume:/output \
  ffmpeg-stream-recorder
```

Optional second channel:
```bash
docker run -d \
  --name channel-two \
  --hostname channel-two \
  -e INPUT_URL="srt://channellive:5421?mode=caller" \
  -e SEGMENT_TIME=180 \
  -v recordings-volume:/output \
  ffmpeg-stream-recorder
```

Environment variables (container-specific):
- INPUT_URL: FFmpeg input URL (e.g., SRT/RTMP/RTSP/RTP/HLS).
- SEGMENT_TIME: Segment length in seconds (e.g., 180).

Recordings are written to `/output` inside the container (mapped to `recordings-volume`).


## 5) Serve recordings via Caddy file server

To easily browse and download your recordings, run a simple file server (Caddy):

```bash
docker run -d \
  --name file-server \
  -v recordings-volume:/output \
  -v "$(pwd)/Caddyfile:/etc/caddy/Caddyfile" \
  -p 8080:8080 \
  caddy:2
```

Access your files at: [http://localhost:8080](http://localhost:8080)

## Credits

This container packages [FFmpeg](https://ffmpeg.org/), a complete, cross-platform solution to record, convert and stream audio and video. FFmpeg is licensed under the [LGPL v2.1+ License](https://www.ffmpeg.org/legal.html).

FFmpeg is a trademark of [Fabrice Bellard](http://bellard.org/), originator of the FFmpeg project.
