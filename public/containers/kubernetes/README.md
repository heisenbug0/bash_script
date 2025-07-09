# Kubernetes Deployment Scripts

Comprehensive Kubernetes deployment scripts for orchestrating containerized applications at scale.

## 📁 Directory Structure

```
kubernetes/
├── manifests/          # Kubernetes manifest templates
│   ├── deployments/   # Deployment configurations
│   ├── services/      # Service definitions
│   ├── ingress/       # Ingress controllers
│   ├── configmaps/    # Configuration management
│   ├── secrets/       # Secret management
│   └── volumes/       # Persistent volume claims
├── helm/              # Helm charts
│   ├── nodejs/        # Node.js applications
│   ├── python/        # Python applications
│   ├── databases/     # Database deployments
│   └── monitoring/    # Monitoring stack
├── operators/         # Custom operators
│   ├── database/      # Database operators
│   ├── monitoring/    # Monitoring operators
│   └── backup/        # Backup operators
├── platforms/         # Platform-specific deployments
│   ├── eks/           # Amazon EKS
│   ├── gke/           # Google GKE
│   ├── aks/           # Azure AKS
│   ├── openshift/     # Red Hat OpenShift
│   └── rancher/       # Rancher Kubernetes
├── networking/        # Network policies and configurations
│   ├── istio/         # Istio service mesh
│   ├── linkerd/       # Linkerd service mesh
│   ├── calico/        # Calico networking
│   └── cilium/        # Cilium networking
└── tools/             # Kubernetes utilities
    ├── monitoring/    # Prometheus, Grafana
    ├── logging/       # ELK, Fluentd
    ├── security/      # Security scanning
    └── backup/        # Backup solutions
```

## 🎯 Deployment Strategies

### Application Deployments
- **Rolling Updates**: Zero-downtime deployments
- **Blue-Green**: Instant rollback capability
- **Canary**: Gradual traffic shifting
- **A/B Testing**: Feature flag deployments

### Scaling Strategies
- **Horizontal Pod Autoscaling**: CPU/Memory based scaling
- **Vertical Pod Autoscaling**: Resource optimization
- **Cluster Autoscaling**: Node-level scaling
- **Custom Metrics**: Application-specific scaling

### Storage Solutions
- **Persistent Volumes**: Stateful applications
- **ConfigMaps**: Configuration management
- **Secrets**: Sensitive data management
- **EmptyDir**: Temporary storage

## 🚀 Quick Start Examples

### Deploy Node.js Application
```bash
cd manifests/nodejs/
export APP_NAME="my-node-app"
export NAMESPACE="production"
export IMAGE="my-registry/node-app:latest"
./deploy.sh
```

### Deploy with Helm
```bash
cd helm/nodejs/
helm install my-app . \
  --set image.repository=my-registry/node-app \
  --set image.tag=latest \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.com
```

### Deploy to AWS EKS
```bash
cd platforms/eks/
export CLUSTER_NAME="my-eks-cluster"
export REGION="us-west-2"
export NODE_GROUP_NAME="worker-nodes"
./setup-cluster.sh
```

### Deploy Monitoring Stack
```bash
cd tools/monitoring/
export NAMESPACE="monitoring"
./deploy-prometheus-grafana.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Cluster Configuration
export CLUSTER_NAME="my-cluster"
export NAMESPACE="default"
export KUBECONFIG="~/.kube/config"

# Application Configuration
export APP_NAME="my-app"
export IMAGE_REPOSITORY="my-registry/my-app"
export IMAGE_TAG="latest"
export REPLICAS="3"

# Resource Configuration
export CPU_REQUEST="100m"
export CPU_LIMIT="500m"
export MEMORY_REQUEST="128Mi"
export MEMORY_LIMIT="512Mi"

# Network Configuration
export SERVICE_TYPE="ClusterIP"
export INGRESS_CLASS="nginx"
export DOMAIN="myapp.com"

# Storage Configuration
export STORAGE_CLASS="gp2"
export VOLUME_SIZE="10Gi"
```

## 📝 Manifest Examples

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
  namespace: production
  labels:
    app: nodejs-app
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
        version: v1
    spec:
      containers:
      - name: nodejs-app
        image: my-registry/nodejs-app:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        securityContext:
          runAsNonRoot: true
          runAsUser: 1001
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```

### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodejs-app-service
  namespace: production
  labels:
    app: nodejs-app
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: nodejs-app
```

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nodejs-app-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.com
    secretName: myapp-tls
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nodejs-app-service
            port:
              number: 80
```

### ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  app.properties: |
    server.port=3000
    logging.level=info
    cache.enabled=true
  nginx.conf: |
    server {
        listen 80;
        server_name myapp.com;
        location / {
            proxy_pass http://nodejs-app-service:80;
        }
    }
```

### Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
data:
  database-url: cG9zdGdyZXNxbDovL3VzZXI6cGFzc0BkYi5leGFtcGxlLmNvbTo1NDMyL2RiCg==
  jwt-secret: bXktand0LXNlY3JldC1rZXkK
  redis-password: bXktcmVkaXMtcGFzc3dvcmQK
```

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nodejs-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nodejs-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

## 📚 Helm Chart Examples

### Chart.yaml
```yaml
apiVersion: v2
name: nodejs-app
description: A Helm chart for Node.js application
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
- name: postgresql
  version: 11.9.13
  repository: https://charts.bitnami.com/bitnami
  condition: postgresql.enabled
- name: redis
  version: 17.3.7
  repository: https://charts.bitnami.com/bitnami
  condition: redis.enabled
```

### values.yaml
```yaml
# Default values for nodejs-app
replicaCount: 3

image:
  repository: my-registry/nodejs-app
  pullPolicy: IfNotPresent
  tag: "latest"

nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext:
  fsGroup: 1001

securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: false
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

# Database configuration
postgresql:
  enabled: true
  auth:
    postgresPassword: "postgres"
    username: "app"
    password: "app123"
    database: "appdb"

# Redis configuration
redis:
  enabled: true
  auth:
    enabled: true
    password: "redis123"

# Application configuration
app:
  env:
    NODE_ENV: production
    LOG_LEVEL: info
  secrets:
    jwtSecret: "my-jwt-secret"
```

## 🛠️ Platform-Specific Deployments

### AWS EKS
```bash
#!/bin/bash
# setup-eks-cluster.sh

CLUSTER_NAME="${CLUSTER_NAME:-my-eks-cluster}"
REGION="${REGION:-us-west-2}"
NODE_GROUP_NAME="${NODE_GROUP_NAME:-worker-nodes}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.medium}"
MIN_SIZE="${MIN_SIZE:-1}"
MAX_SIZE="${MAX_SIZE:-10}"
DESIRED_SIZE="${DESIRED_SIZE:-3}"

# Create EKS cluster
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name $NODE_GROUP_NAME \
  --node-type $INSTANCE_TYPE \
  --nodes $DESIRED_SIZE \
  --nodes-min $MIN_SIZE \
  --nodes-max $MAX_SIZE \
  --managed

# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Install EBS CSI driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
```

### Google GKE
```bash
#!/bin/bash
# setup-gke-cluster.sh

CLUSTER_NAME="${CLUSTER_NAME:-my-gke-cluster}"
ZONE="${ZONE:-us-central1-a}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-medium}"
NUM_NODES="${NUM_NODES:-3}"

# Create GKE cluster
gcloud container clusters create $CLUSTER_NAME \
  --zone $ZONE \
  --machine-type $MACHINE_TYPE \
  --num-nodes $NUM_NODES \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 10 \
  --enable-autorepair \
  --enable-autoupgrade

# Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

## 📊 Monitoring and Observability

### Prometheus + Grafana
```yaml
# prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

grafana:
  adminPassword: admin123
  persistence:
    enabled: true
    storageClassName: gp2
    size: 10Gi
  
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
```

### Logging with ELK Stack
```yaml
# elasticsearch-values.yaml
replicas: 3
minimumMasterNodes: 2

esConfig:
  elasticsearch.yml: |
    cluster.name: "docker-cluster"
    network.host: 0.0.0.0
    discovery.zen.minimum_master_nodes: 2
    discovery.zen.ping.unicast.hosts: "elasticsearch-master-headless"

volumeClaimTemplate:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: gp2
  resources:
    requests:
      storage: 30Gi

# kibana-values.yaml
elasticsearchHosts: "http://elasticsearch-master:9200"

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: kibana.example.com
      paths:
        - path: /
          pathType: ImplementationSpecific
```

## 🔒 Security Best Practices

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: nodejs-app-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: nodejs-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

### Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### RBAC Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: app-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "watch", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: production
roleRef:
  kind: Role
  name: app-reader
  apiGroup: rbac.authorization.k8s.io
```

## 🔍 Troubleshooting

### Common Issues

**Pod Startup Issues**
```bash
# Check pod status
kubectl get pods -n production

# Describe pod for events
kubectl describe pod <pod-name> -n production

# Check pod logs
kubectl logs <pod-name> -n production -f
```

**Service Discovery Issues**
```bash
# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
nslookup nodejs-app-service.production.svc.cluster.local

# Check service endpoints
kubectl get endpoints nodejs-app-service -n production
```

**Resource Issues**
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n production

# Check resource quotas
kubectl describe resourcequota -n production
```

### Performance Optimization

**Resource Tuning**
```bash
# Monitor resource usage
kubectl top pods -n production --sort-by=cpu
kubectl top pods -n production --sort-by=memory

# Check HPA status
kubectl get hpa -n production
kubectl describe hpa nodejs-app-hpa -n production
```

**Network Performance**
```bash
# Test network latency
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- /bin/bash
ping nodejs-app-service.production.svc.cluster.local
```

## 🔗 Related Documentation

- [Docker Scripts](../docker/README.md)
- [Cloud Services](../../cloud-services/README.md)
- [Monitoring Scripts](../../tools/monitoring/README.md)
- [Database Scripts](../../databases/README.md)