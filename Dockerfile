##
# (c) 2021 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
FROM openjdk:11-jdk

CMD ["/bin/sh", "-c", "$JAVA_HOME/bin/java -XX:+UnlockExperimentalVMOptions $JAVA_OPTS $APM_OPTS -jar /var/app/current/bin/app.jar"]
