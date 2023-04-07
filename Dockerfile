ARG RUBY_VERSION=9.4
FROM jruby:${RUBY_VERSION}

# Last digit is needed to get bundler to install the latest.
# Check https://rubygems.org/gems/bundler/versions for the latest version.
ARG UNAME=app
ARG UID=1000
ARG GID=1000

## Install Vim (optional)
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential \
  netbase
  #libicu-dev \
  #vim-tiny

RUN gem install bundler

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

USER $UNAME

ENV BUNDLE_PATH /gems

WORKDIR /app

##For a production build copy the app files and run bundle install
#COPY --chown=${UID}:${GID} . /app
#RUN bundle _${BUNDLER_VERSION}_ install

CMD ["tail", "-f", "/dev/null"]
