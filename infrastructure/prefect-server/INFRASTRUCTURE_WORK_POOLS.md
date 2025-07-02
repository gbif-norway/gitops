# Prefect Infrastructure-Based Work Pools

This document explains how to configure Prefect to use your custom container `gbifnorway/prefect-automations` with infrastructure-based work pools, which dynamically create Kubernetes jobs instead of running persistent workers.

## Overview

Prefect's infrastructure-based work pools create Kubernetes jobs on-demand when tasks need to be executed, rather than running persistent worker pods. This is more efficient and cost-effective for most use cases.

## Prerequisites

1. A running Prefect server (deployed via this chart)
2. Your custom container image `gbifnorway/prefect-automations` must be available
3. Prefect CLI configured to connect to your server
4. **NEW**: RBAC permissions configured for worker jobs (see `prefect-worker-rbac.yaml`)

## RBAC Setup (Required)

Before creating work pools, apply the RBAC configuration to fix authentication errors:

```bash
# Apply the RBAC configuration (update namespace as needed)
kubectl apply -f prefect-worker-rbac.yaml
```

This creates:
- `prefect-worker` ServiceAccount
- `prefect-worker-role` ClusterRole with necessary permissions
- `prefect-worker-binding` ClusterRoleBinding

## Configuration Steps

### 1. Connect to Your Prefect Server

First, configure the Prefect CLI to connect to your server:

```bash
# Set the API URL
prefect config set PREFECT_API_URL=https://prefect.svc.gbif.no/api

# If using basic auth, set the auth string
prefect config set PREFECT_API_AUTH_STRING="admin:your-password"
```

### 2. Create a Work Pool with Kubernetes Infrastructure

Create a work pool that uses Kubernetes infrastructure:

```bash
prefect work-pool create gbif-automations \
  --type kubernetes \
  --base-job-template '{
    "job": {
      "metadata": {
        "namespace": "your-namespace"
      },
      "spec": {
        "template": {
          "spec": {
            "containers": [
              {
                "name": "prefect-job",
                "image": "gbifnorway/prefect-automations:latest",
                "command": ["prefect", "worker", "start"],
                "args": ["--pool", "gbif-automations"],
                "resources": {
                  "requests": {
                    "cpu": "500m",
                    "memory": "1Gi"
                  },
                  "limits": {
                    "cpu": "2",
                    "memory": "4Gi"
                  }
                },
                "env": [
                  {
                    "name": "PREFECT_API_URL",
                    "value": "https://prefect.svc.gbif.no/api"
                  },
                  {
                    "name": "PREFECT_API_AUTH_STRING",
                    "valueFrom": {
                      "secretKeyRef": {
                        "name": "prefect-basic-auth",
                        "key": "auth-string"
                      }
                    }
                  }
                ]
              }
            ],
            "restartPolicy": "Never",
            "serviceAccountName": "prefect-worker"
          }
        }
      }
    }
  }'
```

**Important Change**: The `serviceAccountName` is now set to `"prefect-worker"` instead of `"prefect-server"`.

### 3. Create a Work Queue

Create a work queue for the pool:

```bash
prefect work-queue create default --pool gbif-automations
```

### 4. Deploy Your Flows

When deploying flows, specify the work pool:

```python
from prefect import flow, task
from prefect.deployments import Deployment

@task
def my_task():
    return "Hello from custom container!"

@flow
def my_flow():
    result = my_task.submit()
    return result

# Deploy with the work pool
deployment = Deployment.build_from_flow(
    flow=my_flow,
    name="my-deployment",
    work_pool_name="gbif-automations",
    work_queue_name="default"
)
deployment.apply()
```

## Alternative: Using Prefect's Built-in Kubernetes Infrastructure

Prefect also provides a simpler way using built-in infrastructure types:

### 1. Create Work Pool with Built-in Kubernetes Infrastructure

```bash
prefect work-pool create gbif-automations --type kubernetes
```

### 2. Configure the Work Pool via UI or API

1. Go to the Prefect UI: https://prefect.svc.gbif.no
2. Navigate to Work Pools → gbif-automations → Settings
3. Update the base job template to use your custom container:

```json
{
  "job": {
    "metadata": {
      "namespace": "your-namespace"
    },
    "spec": {
      "template": {
        "spec": {
          "containers": [
            {
              "name": "prefect-job",
              "image": "gbifnorway/prefect-automations:latest",
              "command": ["prefect", "worker", "start"],
              "args": ["--pool", "gbif-automations"],
              "resources": {
                "requests": {
                  "cpu": "500m",
                  "memory": "1Gi"
                },
                "limits": {
                  "cpu": "2",
                  "memory": "4Gi"
                }
              },
              "env": [
                {
                  "name": "PREFECT_API_URL",
                  "value": "https://prefect.svc.gbif.no/api"
                },
                {
                  "name": "PREFECT_API_AUTH_STRING",
                  "valueFrom": {
                    "secretKeyRef": {
                      "name": "prefect-basic-auth",
                      "key": "auth-string"
                    }
                  }
                }
              ]
            }
          ],
          "restartPolicy": "Never",
          "serviceAccountName": "prefect-worker"
        }
      }
    }
  }
}
```

## Monitoring

### Check Work Pool Status

```bash
# List work pools
prefect work-pool ls

# Check work pool details
prefect work-pool inspect gbif-automations
```

### Monitor Jobs

```bash
# Check Kubernetes jobs
kubectl get jobs -n your-namespace

# Check job logs
kubectl logs job/prefect-job-xxxxx -n your-namespace
```

### Check Flow Runs

```bash
# List flow runs
prefect flow-run ls

# Check specific flow run
prefect flow-run inspect <flow-run-id>
```

## Benefits of Infrastructure-Based Work Pools

1. **Cost Efficiency**: No persistent workers running when idle
2. **Resource Optimization**: Jobs are created only when needed
3. **Scalability**: Can handle burst workloads without over-provisioning
4. **Isolation**: Each flow run gets its own clean environment
5. **Custom Containers**: Easy to use different container images per work pool

## Troubleshooting

### Jobs Not Starting

1. Check if the work pool exists and is configured correctly
2. Verify the container image is accessible
3. Check Kubernetes events: `kubectl get events -n your-namespace`
4. Verify service account permissions

### Authentication Issues

1. Ensure the `prefect-basic-auth` secret exists
2. Check that the auth string is correctly formatted
3. Verify the Prefect API URL is accessible from within the cluster

### Resource Issues

1. Check if the cluster has sufficient resources
2. Verify resource requests/limits are appropriate
3. Check for node selectors or taints that might prevent scheduling

## Advanced Configuration

### Custom Resource Definitions

You can add custom resources, volumes, or other Kubernetes specifications to the job template:

```json
{
  "job": {
    "spec": {
      "template": {
        "spec": {
          "volumes": [
            {
              "name": "shared-data",
              "persistentVolumeClaim": {
                "claimName": "shared-pvc"
              }
            }
          ],
          "containers": [
            {
              "volumeMounts": [
                {
                  "name": "shared-data",
                  "mountPath": "/data"
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```

### Multiple Work Pools

You can create multiple work pools for different types of workloads:

```bash
# For CPU-intensive tasks
prefect work-pool create cpu-intensive --type kubernetes

# For memory-intensive tasks  
prefect work-pool create memory-intensive --type kubernetes

# For GPU tasks
prefect work-pool create gpu-tasks --type kubernetes
```

Each work pool can have different resource configurations and container images. 