#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

echo "$PRODUCT_PROPERTIES" > properties.yml
echo "$PRODUCT_RESOURCES" > resources.yml
echo "$PRODUCT_NETWORK_AZS" > network-azs.yml

properties_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < properties.yml)
properties_config=$(echo "$properties_config" | $JQ_CMD 'delpaths([path(.[][][]? | select(type == "null"))]) | delpaths([path(.[][]? | select(. == {}))]) | del(.[][] | nulls) | delpaths([path(.[][] | select(. == ""))]) | delpaths([path(.[] | select(. == {}))])')

resources_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < resources.yml)
network_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < network-azs.yml)

input_length=$(echo $network_config | $JQ_CMD '. | keys | length')
if [[ $input_length != 0 ]]; then
  $OM_CMD \
    --target https://$OPS_MGR_HOST \
    --username "$OPS_MGR_USR" \
    --password "$OPS_MGR_PWD" \
    --skip-ssl-validation \
    configure-product \
    --product-name $PRODUCT_IDENTIFIER \
    --product-network "$network_config"
fi

input_length=$(echo $properties_config | $JQ_CMD '. | keys | length')
if [[ $input_length != 0 ]]; then
  $OM_CMD \
    --target https://$OPS_MGR_HOST \
    --username "$OPS_MGR_USR" \
    --password "$OPS_MGR_PWD" \
    --skip-ssl-validation \
    configure-product \
    --product-name $PRODUCT_IDENTIFIER \
    --product-properties "$properties_config"
fi

input_length=$(echo $resources_config | $JQ_CMD '. | keys | length')
if [[ $input_length != 0 ]]; then
  $OM_CMD \
    --target https://$OPS_MGR_HOST \
    --username "$OPS_MGR_USR" \
    --password "$OPS_MGR_PWD" \
    --skip-ssl-validation \
    configure-product \
    --product-name $PRODUCT_IDENTIFIER \
    --product-resources "$resources_config"
fi
