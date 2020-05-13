# monitor-pv
custom stats collector for OpenEBS persistent volumes (jiva, localpv)

To run monitor-pv in your kubernetes cluster apply the given node-exporter yaml. It will contain two containers i.e node-exporter and monitor-pv. monitor-pv will collect the metrics and will store in a file and node-exporter will read that file and expose the metrics.

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

## Example:
![monitor-pv-1](https://user-images.githubusercontent.com/29499601/81772797-67141a80-9504-11ea-901b-fe165900d60c.png)

![monitor-pv-2](https://user-images.githubusercontent.com/29499601/81772848-8a3eca00-9504-11ea-8d0b-e7a572a06aef.png)

