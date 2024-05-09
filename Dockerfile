FROM debian:bullseye-slim

COPY bellsoft_jdk11.0.1510_linux_amd64_full.deb /opt/dist/
COPY 1c_cs_25.0.22_linux_x86_64.tar.gz /opt/dist/

RUN mkdir -p /usr/share/man/man1 && \
	apt-get update && apt-get install -y \
	wget curl sudo gawk

RUN cd /opt/dist \
	&& tar xzf 1c_cs_25.0.22_linux_x86_64.tar.gz \
	&& dpkg -i bellsoft_jdk11.0.1510_linux_amd64_full.deb;  apt-get -f install -y \
	&& dpkg -i *.deb \
	&& ls /opt/dist \
	&& ./1ce-installer-cli install \
	&& rm -rf * 

RUN apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV JAVA_HOME /usr/lib/jvm/bellsoft-java11-full-amd64
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-openjdk-amd64/bin:/opt/1C/1CE/components/1c-enterprise-ring-0.19.5+12-x86_64/

RUN mkdir -p /var/cs/cs_instance && \
	mkdir -p /var/cs/hc_instance && \
	mkdir -p /var/cs/elastic_instance \
	&& chmod +x /opt/1C/1CE/components/1c-enterprise-ring-0.19.5+12-x86_64/ring 

RUN ring cs instance create --dir /var/cs/cs_instance --owner root \
	&& ring hazelcast instance create --dir /var/cs/hc_instance --owner root \
	&& ring elasticsearch instance create --dir /var/cs/elastic_instance --owner root

RUN mv /bin/pidof /bin/_pidof && cp /bin/echo /bin/pidof 

RUN ring hazelcast --instance hc_instance service create --username root --stopped --java-home $JAVA_HOME 
RUN ring elasticsearch --instance elastic_instance service create --username root --stopped --java-home $JAVA_HOME
RUN ring cs --instance cs_instance service create --username root --stopped --java-home $JAVA_HOME

COPY run.sh /
COPY init.sh /
COPY restart.sh /
RUN chmod +x /*.sh

ENV POSTGRES_URL "postgres:5432/cs"
ENV POSTGRES_USER "postgres"
ENV POSTGRES_PASSWORD "postgres"

EXPOSE 8181
CMD ["/run.sh"]
