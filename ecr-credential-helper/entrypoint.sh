#!/usr/bin/env sh

SECRET_NAME="$AWS_DEFAULT_REGION-ecr-registry"
TOKEN=$(aws ecr get-login --region "$AWS_DEFAULT_REGION" --registry-ids "$AWS_ACCOUNT_ID" | cut -d' ' -f6)
echo "Beginning processing namespaces: $NAMESPACES."
for NAMESPACE in $NAMESPACES
do
  echo "Working on namespace $NAMESPACE."
  kubectl -n "$NAMESPACE" delete secret --ignore-not-found "$SECRET_NAME"
  kubectl -n "$NAMESPACE" create secret docker-registry "$SECRET_NAME" \
    --docker-server="https://$ACCOUNT.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com" \
    --docker-username=AWS \
    --docker-password="$TOKEN" \
    --docker-email="$EMAIL"
  echo "Secret created by name in namespace $NAMESPACE. $SECRET_NAME"
  kubectl -n "$NAMESPACE" patch serviceaccount default -p '{"imagePullSecrets":[{"name":"'$SECRET_NAME'"}]}'
done
echo "All done."
