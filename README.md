# monitor-pv
custom stats collector for OpenEBS persistent volumes (jiva, localpv)

### Pre-requisite
- openebs (https://docs.openebs.io/)

### How to use
- Run `kubectl apply -f node-exporter-pv-metrics.yaml`
- Verify if the pods are up and running.
<pre>
$ kubectl get pods -n openebs 
NAME                                                              READY   STATUS    RESTARTS   AGE
cspc-operator-6c4cc7c64d-698ps                                    1/1     Running   0          6d23h
cvc-operator-77d749c559-9phff                                     1/1     Running   0          6d23h
maya-apiserver-5fb947d74d-r9skp                                   1/1     Running   0          6d23h
<b>monitor-pv-bvzgv                                                  2/2     Running   0          8s
monitor-pv-nk76b                                                  2/2     Running   0          11s
monitor-pv-wnvp5                                                  2/2     Running   0          8s</b>
openebs-admission-server-6c4b4998f8-zcg9n                         1/1     Running   0          6d23h
openebs-localpv-provisioner-5b744fc789-5wr8d                      1/1     Running   0          6d23h
openebs-ndm-g474w                                                 1/1     Running   0          6d23h
openebs-ndm-k2nnp                                                 1/1     Running   0          6d23h
openebs-ndm-operator-b58c79cc5-z8zw6                              1/1     Running   1          6d23h
openebs-ndm-rwzrb                                                 1/1     Running   0          6d23h
openebs-provisioner-54d45b55db-rt5rv                              1/1     Running   0          6d23h
openebs-snapshot-operator-6d4f5d7688-6g7zw                        2/2     Running   0          6d23h
pvc-dd03f0ae-731c-4f78-bdbf-86485f32ab3d-ctrl-89b44f6cb-pbnmk     2/2     Running   0          40h
pvc-dd03f0ae-731c-4f78-bdbf-86485f32ab3d-rep-1-857b65c68d-qrdx9   1/1     Running   0          40h
pvc-dd03f0ae-731c-4f78-bdbf-86485f32ab3d-rep-2-58c4f54f7-m6n45    1/1     Running   0          40h

</pre>

### How it works
The monitor PV daemonset pods consist of two containers i.e node-exporter and monitor-pv. The monitor-pv collects the PV size and PV utilization information & places it in a file on the shared mount. The node exporter uses its text-file collector to expose this data as metrics.

It exposes two metrics **pv_capacity_bytes** and **pv_utilization_bytes**.

### Prometheus Configuration
To scrape the metrics in prometheus add this configuration in prometheus configuration file:
<pre>
    - job_name: 'monitor-pv'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        regex: monitor-pv
        action: keep
</pre>

If you want to scrape only monitor-pv metrics and drop all other node-exporter metrics use the below configuration:
<pre>
    - job_name: 'monitor-pv'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        regex: monitor-pv
        action: keep
      metric_relabel_configs:
      - source_labels: [__name__]
        regex: '(pv_capacity_bytes|pv_utilization_bytes)'
        action: keep
</pre>

### Example:
![monitor-pv-1](https://user-images.githubusercontent.com/29499601/81772797-67141a80-9504-11ea-901b-fe165900d60c.png)

![monitor-pv-2](https://user-images.githubusercontent.com/29499601/81772848-8a3eca00-9504-11ea-8d0b-e7a572a06aef.png)

