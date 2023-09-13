FROM ruby:3.1

# Check https://rubygems.org/gems/bundler/versions for the latest version.
ARG UNAME=app
ARG UID=1000
ARG GID=1000

## Install Vim (optional)
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  vim-tiny

RUN gem install bundler

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

USER $UNAME

ENV BUNDLE_PATH /gems
ENV BUNDLE_BUILD__ICU "--use-system-libraries"

WORKDIR /app

##For a production build copy the app files and run bundle install
#COPY --chown=${UID}:${GID} . /app
#RUN bundle _${BUNDLER_VERSION}_ install

CMD ["tail", "-f", "/dev/null"]
