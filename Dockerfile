ARG RUBY_VERSION=3.2.2
FROM ruby:${RUBY_VERSION}

# Check https://rubygems.org/gems/bundler/versions for the latest version.
ARG UNAME=app
ARG UID=1000
ARG GID=1000

## Install Vim (optional)
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential \
  netbase \
  libicu72 \
  libicu-dev \
  icu-devtools


RUN groupadd -g ${GID} -o ${UNAME}
RUN #groupadd -g app -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

ENV BUNDLE_PATH /gems
ENV GEM_HOME /gems

RUN gem install bundler
USER $UNAME


WORKDIR /app

##For a production build copy the app files and run bundle install
#COPY --chown=${UID}:${GID} . /app
#RUN bundle _${BUNDLER_VERSION}_ install

CMD ["tail", "-f", "/dev/null"]
