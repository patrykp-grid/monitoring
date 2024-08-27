# First stage: Build the application
FROM eclipse-temurin:17-jdk-jammy as build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and configuration files
COPY mvnw ./
COPY .mvn .mvn

# Copy the pom.xml file to download dependencies
COPY pom.xml ./

# Download dependencies; this is a separate step to take advantage of Docker caching
RUN ./mvnw dependency:go-offline -B

# Copy the actual source code of the application
COPY src ./src

# Build the application
RUN ./mvnw package -DskipTests -B

# Second stage: Create the runtime image with only necessary files
FROM eclipse-temurin:17-jre-jammy as runtime

# Set a non-root user
RUN addgroup --system spring && adduser --system spring --ingroup spring
USER spring:spring

# Set the working directory inside the container
WORKDIR /app

# Copy the built JAR file from the build stage
COPY --from=build /app/target/*.jar ./app.jar

# Copy the JMX Exporter JAR to the container
COPY jmx_prometheus_javaagent-0.16.1.jar /app/jmx_prometheus_javaagent.jar
COPY config.yml /app/config.yml
# Expose the application and JMX Exporter ports
EXPOSE 8080
EXPOSE 8082
EXPOSE 8081
EXPOSE 8083
EXPOSE 8085
EXPOSE 1234

# Run the application with the JMX Exporter agent
ENTRYPOINT ["java", "-javaagent:/app/jmx_prometheus_javaagent.jar=1234:/app/config.yml", "-jar", "/app/app.jar"]
