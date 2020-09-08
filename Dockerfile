FROM gcr.io/google_containers/pause:3.1 AS BPause

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.2

ENV OC_VERSION=v3.11.0 \
    OC_VERSION_COMMIT=0cbc58b \
    TINI_VERSION=v0.19.0

COPY --from=BPause /pause /usr/sbin/

RUN microdnf -y install --nodocs iproute iputils iptables tar gzip \
  && cd /tmp \
  && curl -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /tini \
  && chmod +x /tini \
  && curl -LO https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_COMMIT}-linux-64bit.tar.gz \
  && tar xfz openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_COMMIT}-linux-64bit.tar.gz \
  && cp openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_COMMIT}-linux-64bit/{oc,kubectl} /usr/sbin \
  && chmod +x /usr/sbin/{oc,kubectl} \
  && rm -rf openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_COMMIT}-linux-64bit openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_COMMIT}-linux-64bit.tar.gz \
  && microdnf remove tar

COPY docker-entrypoint.sh /

USER 0

ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]
