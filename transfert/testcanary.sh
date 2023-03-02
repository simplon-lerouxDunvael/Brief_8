set -x
sleep 30
CANARY_REPLICAS=$(kubectl get deployment alfred-voteapp-canary -n prod -o=jsonpath='{.spec.replicas}')
PROD_REPLICAS=$(kubectl get deployment alfred-voteapp -n prod -o=jsonpath='{.spec.replicas}')
echo "Canary replicas: $CANARY_REPLICAS, Prod replicas: $PROD_REPLICAS"
if [ "$CANARY_REPLICAS" == "1" ] && [ "$PROD_REPLICAS" == "2" ]; then
    echo "Canary deployment successful"
else
    echo "Canary deployment failed"
    exit 1
fi