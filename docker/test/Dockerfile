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

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock package.json yarn.lock /app/
RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle config set --local path vendor/ruby && \
    bundle install -j $(nproc) && \
    yarn

COPY . /app
