#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM eclipse-temurin:25-jre-noble

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

ENV TOMCAT_MAJOR 10
ENV TOMCAT_VERSION 10.1.46
ENV TOMCAT_SHA512 20da89fa77fb8d4dbfccf6c68383751348169542aad9d3cbcaf82011337355b9847b883cc71678fa6cc71ef3f55e8d5d7a09a53238b86011816fa989f9c4ff5e

COPY --from=tomcat:10.1.46-jdk25-temurin-noble $CATALINA_HOME $CATALINA_HOME
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

# upstream eclipse-temurin-provided entrypoint script caused https://github.com/docker-library/tomcat/issues/77 to come back as https://github.com/docker-library/tomcat/issues/302; use "/entrypoint.sh" at your own risk
ENTRYPOINT []

CMD ["catalina.sh", "run"]
