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

# Plugins prod : charges via docker/prod/Gemfile.prod (depots publics uniquement).
# Voir docker/prod/Gemfile.prod pour la liste exhaustive.
ENV CUSTOM_PLUGIN_GEMFILE=/app/docker/prod/Gemfile.prod

# Surcharge BUNDLE_PATH de l'image de base (par defaut /usr/local/bundle, root-owned)
# pour pointer sur un repertoire app-local writable par l'utilisateur ekylibre.
# Sinon `bundle install` casse au premier `gem ..., git: '...'` (cache git).
ENV BUNDLE_PATH=/app/vendor/bundle \
    BUNDLE_APP_CONFIG=/app/.bundle

RUN mkdir /app
WORKDIR /app

COPY . /app

# Supprime Gemfile.local (config plugins dev, peut referencer des paths locaux).
# La config plugins prod vient de docker/prod/Gemfile.prod (via CUSTOM_PLUGIN_GEMFILE).
RUN rm -f /app/Gemfile.local /app/Gemfile.local.lock /app/Gemfile.plugins

RUN mkdir -p /app/vendor/bundle /app/.bundle /app/private /app/tmp && \
    addgroup --gid $GID ekylibre && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -g $GID -u $UID ekylibre && \
    chown -R ekylibre:ekylibre /app

USER ekylibre

# Impression PDF : templates HTML (Liquid) convertis par WeasyPrint ;
# lecture locale des justificatifs (plugin Qonto) : PyMuPDF (paquets Debian).

RUN bundle config set --local without 'development test' && \
    bundle install -j $(nproc) && \
    bundle clean --force

RUN yarn install --frozen-lockfile

RUN NODE_OPTIONS=--openssl-legacy-provider \
    SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rake assets:precompile

RUN chmod +x docker/prod/startup.sh docker/prod/jobs_startup.sh
