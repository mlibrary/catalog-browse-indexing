# catalog-browse-indexing

This is repository has the code that loads the solr collections and the solr configuration for those collections for Catalog Browse in Library Search. 

## Developer setup

1. Run the `init.sh` script. This is not a complicated script. It copies over
   env.example to .env, copies over a precommit hook, builds the image, and
   installs the gems. This script is safe to rerun at any time.

```
`./init.sh`
```

2. Fill out the `.env` file with the secrets you need to run the project.

That's it. 🎉

## Taking a look at the local SolrCloud

```
docker compose up
```

Then go to http://localhost:8983/solr in your browser. The login credentials are in `env.development`.
