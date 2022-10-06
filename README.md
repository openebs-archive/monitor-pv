# monitor-pv

custom stats collector for OpenEBS persistent volumes (jiva, localpv)

## Pre-requisite

- openebs (https://docs.openebs.io/)

## How to use

- Run `kubectl apply -f monitor-pv.yaml`
- Verify if the pods are up and running.

```console
$ kubectl get pods -n openebs 
NAME                READY   STATUS    RESTARTS   AGE
...
monitor-pv-bvzgv    2/2     Running   0          8s
monitor-pv-nk76b    2/2     Running   0          11s
monitor-pv-wnvp5    2/2     Running   0          8s
...
```

## How it works

The monitor PV daemonset pods consist of two containers i.e nginx and monitor-pv. The monitor-pv collects the PV size via `kubectl` and PV utilization information via `du`, and then places it in a text file on the shared emptydir mount. The nginx exposes this text file via HTTP so that Prometheus can scrape it as metrics.

It exposes two metrics **pv_capacity_bytes** and **pv_utilization_bytes**.

The pods are configured with Prometheus annotations so that a Prometheus instance installed in the cluster knows how to scrape:

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    prometheus.io/path: /scrape.txt
    prometheus.io/port: "80"
    prometheus.io/scrape: "true"
```

## Example

![monitor-pv-1](https://user-images.githubusercontent.com/29499601/81772797-67141a80-9504-11ea-901b-fe165900d60c.png)

![monitor-pv-2](https://user-images.githubusercontent.com/29499601/81772848-8a3eca00-9504-11ea-8d0b-e7a572a06aef.png)

