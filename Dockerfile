FROM java

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN set -ex \
	&& for key in \
		05AB33110949707C93A279E3D3EFE6B686867BA6 \
		07E48665A34DCAFAE522E5E6266191C37C037D42 \
		47309207D818FFD8DCD3F83F1931D684307A10A5 \
		541FBE7D8F78B25E055DDEE13C370389288584E7 \
		61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
		79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
		9BA44C2621385CB966EBA586F72C284D731FABEE \
		A27677289986DB50844682F8ACB77FC2E86E29AC \
		A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
		DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
		F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
		F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23 \
	; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done

ENV JAVA_MAJOR_VER 0
ENV APR_VER 0
ENV APR_UTIL_VER 0
ENV TOMCAT_NATIVE_VERSION 0

#Install Apache Portable Runtime
RUN	set -x \
	&& apt-get update \
	&& apt-get install -yq gcc make libssl-dev libapr1 libapr1-dev openjdk-${JAVA_MAJOR_VER}-jdk="$JAVA_DEBIAN_VERSION"  \
	&&	curl https://www.apache.org/dist/apr/$APR_VER.tar.gz | tar xvz -C /tmp \
	&& cd /tmp/$APR_VER  \
	&& ./configure  \
	&& make   \
	&& make install  \
	&&	curl https://www.apache.org/dist/apr/$APR_UTIL_VER.tar.gz | tar xvz -C /tmp \
	&& cd /tmp/$APR_UTIL_VER \
	&& ./configure --with-apr=/usr/local/apr  \
	&& make  \
	&& make install \
	&&	curl https://www.apache.org/dist/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VERSION}/source/tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz  | tar xvz -C /tmp \
	&& cd /tmp/tomcat-native*-src/jni/native/ \
	&& ./configure --with-apr=/usr/bin/apr-1-config --with-java-home=$JAVA_HOME/.. --with-ssl=yes --libdir=/usr/lib/jni \
	&& make \
	&& make install	\
	&& apt-get purge -y openjdk-${JAVA_MAJOR_VER}-jdk="$JAVA_DEBIAN_VERSION" gcc make libssl-dev libapr1-dev \
	&& apt-get -y autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV TOMCAT_MAJOR 0
ENV TOMCAT_VERSION 0
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm bin/*.gz \
	&& rm tomcat.tar.gz*

EXPOSE 8080
CMD ["catalina.sh", "run"]
