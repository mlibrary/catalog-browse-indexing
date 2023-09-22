export $(grep -v '^#' .env | xargs -d '\n')
cd conf
rm ../authority_browse.zip
zip -r ../authority_browse.zip .
cd ..
curl -u $user:$password -X DELETE   "$host/api/cluster/configs/authority_browse"
curl -u $user:$password -X PUT   --header "Content-Type: application/octet-stream"   --data-binary @authority_browse.zip   "$host/api/cluster/configs/authority_browse"
curl -u $user:$password "$host/solr/admin/collections?action=DELETE&name=authority_browse"
curl -u $user:$password "$host/solr/admin/collections?action=CREATE&name=authority_browse&numShards=1&collection.configName=authority_browse"
