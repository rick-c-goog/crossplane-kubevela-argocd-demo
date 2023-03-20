export TEAM_NAME=$1

export CLUSTER_NAME=$(\
    kubectl get composite \
    --selector app.kubernetes.io/instance=$TEAM_NAME \
    --output jsonpath="{.items[0].status.clusterName}")

export KUBECONFIG=$PWD/kubeconfig.yaml

mkdir -p $TEAM_NAME-apps

touch $TEAM_NAME-apps/dummy

cp -R team-app-reqs $TEAM_NAME-app-reqs

gcloud container clusters get-credentials $CLUSTER_NAME --zone=us-central1-a

kubectl create namespace production

argocd login localhost:8080 --insecure --username admin --password $PASS
argocd cluster add \
    $(kubectl config current-context) \
    --name $TEAM_NAME

export SERVER_URL=$(kubectl config view \
    --minify \
    --output jsonpath="{.clusters[0].cluster.server}")

cat orig/team-app-reqs.yaml \
    | sed -e "s@server: .*@server: $SERVER_URL@g" \
    | tee production/$TEAM_NAME-app-reqs.yaml

cat orig/team-apps.yaml \
    | sed -e "s@server: .*@server: $SERVER_URL@g" \
    | tee production/$TEAM_NAME-apps.yaml

git add .

git commit -m "Team A apps"

git push

