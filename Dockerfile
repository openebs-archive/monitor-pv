FROM ubuntu:22.04 AS build
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

ARG KUBE_LATEST_VERSION="v1.25.2"
RUN cd /root \
    && curl -LO https://dl.k8s.io/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl \
    && curl -LO https://dl.k8s.io/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl.sha256 \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && chmod -v +x kubectl

FROM ubuntu:22.04 AS final

COPY --from=build /root/kubectl /usr/local/bin/kubectl
COPY textfile_collector.sh /

ENTRYPOINT ["/textfile_collector.sh"]
LABEL maintainer="OpenEBS"
