#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM openjdk:11-jre-buster

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

# see https://www.apache.org/dist/tomcat/tomcat-10/KEYS
# see also "versions.sh" (https://github.com/docker-library/tomcat/blob/master/versions.sh)
ENV GPG_KEYS A9C5DF4D22E99998D9875A5110C01C5A2F6059E7

ENV TOMCAT_MAJOR 10
ENV TOMCAT_VERSION 10.0.16
ENV TOMCAT_SHA512 9b70f4db2c7b2efb5453cd581322b1137df7b6443acd6a8e278eaaf97de89c9ad0c7c7996a2d545ef1e4d965aca43c40d2b2c7d5e46b021695f87093143fbba2

COPY --from=tomcat:10.0.16-jdk11-openjdk-buster $CATALINA_HOME $CATALINA_HOME
RUN set -eux; \
	apt-get update; \
	xargs -rt apt-get install -y --no-install-recommends < "$TOMCAT_NATIVE_LIBDIR/.dependencies.txt"; \
	rm -rf /var/lib/apt/lists/*

# verify Tomcat Native is working properly
RUN set -eux; \
	nativeLines="$(catalina.sh configtest 2>&1)"; \
	nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')"; \
	nativeLines="$(echo "$nativeLines" | sort -u)"; \
	if ! echo "$nativeLines" | grep -E 'INFO: Loaded( APR based)? Apache Tomcat Native library' >&2; then \
		echo >&2 "$nativeLines"; \
		exit 1; \
	fi

EXPOSE 8080
CMD ["catalina.sh", "run"]
