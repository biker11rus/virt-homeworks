FROM centos:7

label version="0.1"

RUN groupadd elastic_group \
    && useradd -g elastic_group elastic_user

add elasticsearch-7.15.2-linux-x86_64.tar.gz /

copy elasticsearch.yml /elasticsearch-7.15.2/config/

RUN mkdir /var/log/logs \
    && chown elastic_user:elastic_group /var/log/logs \
    && mkdir /var/lib/data \
    && chown elastic_user:elastic_group  /var/lib/data \
    && chown -R elastic_user:elastic_group  /elasticsearch-7.15.2/
RUN mkdir /elasticsearch-7.15.2/snapshots &&\
    chown elastic_user:elastic_group  /elasticsearch-7.15.2/snapshots
    
EXPOSE 9200/tcp

USER elastic_user

CMD ["/usr/sbin/init"]
CMD ["/elasticsearch-7.15.2/bin/elasticsearch"]