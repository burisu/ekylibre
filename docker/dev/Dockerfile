# FROM registry.gitlab.com/ekylibre/docker-base-images/ruby2.6:2
FROM ghcr.io/ekylibre/docker-base-images/ruby2.6:latest

ARG UID=1000
ARG GID=1000

RUN mkdir /app
WORKDIR /app

COPY . /app

RUN mkdir -p /app/vendor/bundle && \
    addgroup --gid $GID ekylibre  && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -g $GID -u $UID ekylibre && \
    chown -R ekylibre:ekylibre /app

RUN chmod +x docker/dev/jobs_startup.sh

USER ekylibre

# Lecture locale des justificatifs (plugin Qonto) : PyMuPDF ; tesseract et python3 sont dans l'image de base.
RUN pip3 install --user --no-cache-dir pymupdf==1.26.5

# Impression PDF : templates HTML (Liquid) convertis par WeasyPrint.
RUN pip3 install --user --no-cache-dir weasyprint==62.3
ENV PATH="/home/ekylibre/.local/bin:${PATH}"
 