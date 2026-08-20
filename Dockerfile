# ==========================================
# Stage 1 - Maven Build
# ==========================================
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /build

COPY pom.xml .
COPY src ./src
COPY WebContent ./WebContent

RUN mvn -B clean package -DskipTests


# ==========================================
# Stage 2 - Tomcat Runtime
# ==========================================
FROM tomcat:10.1-jdk17-temurin

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy application WAR
COPY --from=builder /build/target/*.war \
     /usr/local/tomcat/webapps/ROOT.war

# Change Tomcat port from 8080 to 9090
RUN sed -i 's/port="8080"/port="9090"/' \
    /usr/local/tomcat/conf/server.xml

# OpenShift runs containers with an arbitrary non-root UID.
# Give group 0 permission to write to required Tomcat directories.
RUN chgrp -R 0 /usr/local/tomcat && \
    chmod -R g+rwX /usr/local/tomcat

EXPOSE 9090

CMD ["catalina.sh", "run"]