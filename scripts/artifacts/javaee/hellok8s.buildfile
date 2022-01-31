FROM websphere-liberty:19.0.0.9-webProfile8-java11

COPY --chown=1001:0 ./javaee/HelloK8s.war /config/dropins/
