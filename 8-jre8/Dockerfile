FROM java:8-jre

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
	05AB33110949707C93A279E3D3EFE6B686867BA6 \
	07E48665A34DCAFAE522E5E6266191C37C037D42 \
	47309207D818FFD8DCD3F83F1931D684307A10A5 \
	541FBE7D8F78B25E055DDEE13C370389288584E7 \
	61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
	79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
	80FF76D88A969FE46108558A80B953A041E49465 \
	8B39757B1D8A994DF2433ED58B3A601F08C975E5 \
	B3F49CD3B9BD2996DA90F817ED3873F5D3262722 \
	713DA88BE50911535FE716F5208B0AB1D63011C7 \
	9BA44C2621385CB966EBA586F72C284D731FABEE \
	A27677289986DB50844682F8ACB77FC2E86E29AC \
	A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
	DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
	F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
	F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

ENV JAVA_MAJOR_VER 8
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.32
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --verify tomcat.tar.gz.asc \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz*

ENV APR_VER apr-1.5.2
ENV APR_UTIL_VER apr-util-1.5.4
ENV TOMCAT_NATIVE_VERSION 1.1.34

#Install Apache Portable Runtime
RUN	set -x \
	&& apt-get update \
	&& apt-get install -yq build-essential gcc make openssl libssl-dev libapr1 libapr1-dev openjdk-${JAVA_MAJOR_VER}-jdk="$JAVA_DEBIAN_VERSION"  \
	&&	curl https://www.apache.org/dist/tomcat/apr/$APR_VER.tar.gz | tar xvz -C /tmp \
	&&	curl https://www.apache.org/dist/apr/$APR_UTIL_VER.tar.gz | tar xvz -C /tmp \
	&&	curl https://www.apache.org/dist/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VERSION}/source/tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz  | tar xvz -C /tmp \
	&& cd /tmp/$APR_VER  \
	&& ./configure  \
	&& make   \
	&& make install  \
	&& cd /tmp/$APR_UTIL_VER \
	&& ./configure --with-apr=/usr/local/apr  \
	&& make  \
	&& make install \
	&& cd /tmp/tomcat-native*-src/jni/native/ \
	&& ./configure --with-apr=/usr/bin/apr-1-config --with-java-home=$JAVA_HOME/.. --with-ssl=yes --libdir=/usr/lib/jni \
	&& make \
	&& make install	\
	&& apt-get purge -y openjdk-${JAVA_MAJOR_VER}-jdk="$JAVA_DEBIAN_VERSION" gcc make libssl-dev libapr1-dev \
	&& apt-get -y autoremove \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*\
	&& apt-get clean

EXPOSE 8080
CMD ["catalina.sh", "run"]
