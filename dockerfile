FROM adoptopenjdk/openjdk11:jre-11.0.9.1_1-alpine@sha256:b6ab039066382d39cfc843914ef1fc624aa60e2a16ede433509ccadd6d995b1f


# Install packages needed
RUN apk update && apk add --update --no-cache \
    tomcat-native \
    python3 \
    apk-cron \
    py3-pip \
    && pip3 install --upgrade pip \
    && pip3 install \
        awscli \
    && rm -rf /var/cache/apk/*

# Make sure AWS cli is installed
RUN aws --version


# Copy jar file
ADD target/S3FileUpload-1.0.jar S3FileUpload-1.0.jar

# Expose port 8443 on the container
EXPOSE 8080

# Run jar file

CMD "java" "-jar" "S3FileUpload-1.0.jar"