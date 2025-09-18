# FFmpeg Stream Recorder with Docker

This project provides a solution for recording various media streams using FFmpeg and Docker, and makes those recordings easily accessible via a web server.

Below are example Docker commands for recording streams with FFmpeg and making the recordings easily accessible.

> **Note:** These commands are **not limited to SRT**. They also work with other streaming protocols supported by FFmpeg such as **RTP, UDP, TCP, RTMP, RTSP, HLS**, etc.  
> Make sure your FFmpeg build includes the necessary protocol and demuxer support. Example FFmpeg build args:
>
> ```bash
> --enable-protocol=rtp \
> --enable-protocol=udp \
> --enable-protocol=tcp \
> --enable-protocol=srt \
> --enable-demuxer=mpegts
> ```

---

## 1. Raw FFmpeg Command Example

This is the core `ffmpeg` command used for recording. The Docker container wraps this logic.

```bash
ffmpeg -i srt://localhost:5421?mode=caller -c copy -f segment -segment_time 180 -reset_timestamps 1 -strftime 1 ut_%Y%m%d_%H%M.mp4
```

Replace the input URL with your desired protocol/stream as needed.

---

## 2. Build the Docker Image

First, build the Docker image for the stream recorder.

### Standard build:

```bash
docker build --build-arg FFMPEG_VERSION=n7.0.2 -t ffmpeg-stream-recorder .
```

### No-cache build:

```bash
docker build --no-cache --build-arg FFMPEG_VERSION=n7.0.2 -t ffmpeg-stream-recorder .
```

---

## 3. Create a Docker Volume

Create a Docker volume to store the recordings persistently.

```bash
docker volume create recordings-volume
```

---

## 4. Run the Stream Recorder Container

Now, run the recorder container.  
**You can change `INPUT_URL` to use any supported protocol (e.g., rtp://, udp://, tcp://, rtsp://, etc.):**

```bash
docker run -d \
  --name channel-one \
  --hostname channel-one \
  -e INPUT_URL="srt://localhost:5421?mode=caller" \
  -e SEGMENT_TIME=180 \
  -v recordings-volume:/output \
  ffmpeg-stream-recorder
```
Optional

```bash
docker run -d \
  --name channel-two \
  --hostname channel-two \
  -e INPUT_URL="srt://channellive:5421?mode=caller" \
  -e SEGMENT_TIME=180 \
  -v recordings-volume:/output \
  ffmpeg-stream-recorder
```

---

## 5. Serve Recordings via Caddy File Server

To easily browse and download your recordings, run a simple file server.

```bash
docker run -d \
  --name file-server \
  -v recordings-volume:/output \
  -v $(pwd)/Caddyfile:/etc/caddy/Caddyfile \
  -p 8080:8080 \
  caddy:2
```

Access your files at: [http://localhost:8080](http://localhost:8080)

---

> **Tip:** Adjust environment variables and ports according to your requirements.  
> Ensure your FFmpeg image is built with the protocols and demuxers you need.