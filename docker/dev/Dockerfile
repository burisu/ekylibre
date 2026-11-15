# Ruby 4 on Debian trixie: no Java nor LibreOffice (PDF printing by WeasyPrint)
FROM ruby:4.0-trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
      libgeos-dev libproj-dev proj-data \
      libpq-dev postgresql-client \
      imagemagick ghostscript poppler-utils tesseract-ocr tesseract-ocr-fra \
      gnupg libgpgme-dev libxml2-dev libxslt1-dev libyaml-dev \
      weasyprint python3-pymupdf \
      nodejs npm \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

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

# Impression PDF : templates HTML (Liquid) convertis par WeasyPrint ;
# lecture locale des justificatifs (plugin Qonto) : PyMuPDF (paquets Debian).
 