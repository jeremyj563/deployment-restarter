# Kubernetes Deployment Restarter

## Synopsis
A simple docker image for automating deployment restarts from within a Kubernetes `Pod`

## Description
- Requires `ServiceAccount/default` to have access to `patch` the target `Deployment`
- When creating the container you must be sure to set the `NAMESPACE` and `DEPLOYMENT` environment variables
- Can be used with ArgoCD if desired

## Example
```yaml
# role.yml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-restarter
  namespace: <namespace>
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - patch
```
```yaml
# rolebinding.yml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployment-restarter
  namespace: <namespace>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployment-restarter
subjects:
- kind: ServiceAccount
  name: default
  namespace: <namespace>
```
```yaml
# job.yml
---
apiVersion: batch/v1
kind: Job
metadata:
  generateName: <deployment-name>-deployment-restarter-
  namespace: <namespace>
  annotations:
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: deployment-restarter
        image: davenportiowa/deployment-restarter:latest
        imagePullPolicy: Always
        env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: DEPLOYMENT
          value: <deployment-name>
      restartPolicy: Never
  backoffLimit: 2
```