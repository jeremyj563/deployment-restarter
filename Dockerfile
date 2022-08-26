# docker build . -t davenportiowa/deployment-restarter:latest
# docker push davenportiowa/deployment-restarter:latest

FROM alpine/curl:latest
LABEL Author Jeremy Johnson <jeremy.m.johnson@davenportiowa.com>

ENV API_SERVER=https://kubernetes.default.svc
ENV API_PARAMS=fieldManager=kubectl-rollout&pretty=true
ENV SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
ENV CACERT=${SERVICEACCOUNT}/ca.crt

ENTRYPOINT \
  export API_ENDPOINT=apis/apps/v1/namespaces/${NAMESPACE}/deployments/${DEPLOYMENT} \
  export TOKEN=$(cat $SERVICEACCOUNT/token) \
  export RESTARTED_AT=$(date +"%Y-%m-%dT%H:%M:%SZ") && \
  curl \
  --request PATCH "${API_SERVER}/${API_ENDPOINT}?${API_PARAMS}" \
  --header "Content-Type: application/strategic-merge-patch+json" \
  --header "Authorization: Bearer ${TOKEN}" \
  --cacert ${CACERT} \
  --data-raw '{ \
    "spec": { \
      "template": { \
        "metadata": { \
          "annotations": { \
            "kubectl.kubernetes.io/restartedAt": "'"${RESTARTED_AT}"'" \
            } \
          } \
        } \
      } \
    }'