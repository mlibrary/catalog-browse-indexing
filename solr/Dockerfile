FROM solr:8.11.2

# Configure for basic auth
ENV SOLR_AUTH_TYPE="basic"
ENV SOLR_AUTHENTICATION_OPTS="-Dbasicauth=solr:SolrRocks"
ENV SOLR_OPTS="-Denable.packages=true"


# One of the places solr will always look for .jar files, and where zookeeper
# will always make sure it can find them, is in `solr.solr.home`/lib.
# We'll go ahead and make that directory, and put all our jars in it.

ENV SOLR_HOME=/var/solr/data
ENV SOLR_LIB=/var/solr/data/lib
RUN mkdir -p $SOLR_LIB

# Now copy everything from our local solr/lib to that location, so all the
# replicas can find them

COPY --chown=solr:solr lib/*.jar $SOLR_LIB

# Set up a security.json so we can actually log in

COPY --chown=solr:solr dev_init/security.json /var/solr/data/security.json
COPY --chown=solr:solr dev_init/solr_init.sh /usr/bin/solr_init.sh
ENTRYPOINT ["/usr/bin/solr_init.sh"]

