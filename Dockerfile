FROM openjdk:11-jdk

CMD ["/bin/sh", "-c", "$JAVA_HOME/bin/java -XX:+UnlockExperimentalVMOptions $JAVA_OPTS $APM_OPTS -jar /var/app/current/bin/app.jar"]
