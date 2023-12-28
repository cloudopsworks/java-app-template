##
# (c) 2021 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
FROM openjdk:17-jdk

RUN mkdir /var/app
RUN groupadd -g 999 webapp
RUN useradd -d /var/app -g webapp -u 999 webapp
RUN chown 999:999 /var/app
WORKDIR /var/app
COPY target/*.jar app.jar
USER webapp:webapp

CMD ["/bin/sh", "-c", "$JAVA_HOME/bin/java $JAVA_OPTS $APM_OPTS -jar app.jar"]
