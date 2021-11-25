FROM armdocker.rnd.ericsson.se/proj-eo-cm/eric-eo-cm-sles-base-python3:latest
RUN mkdir /testSDK
RUN zypper -n install openssh
COPY file-uploader.py testSDK/file-uploader.py
COPY file-remove_tlsoff.py testSDK/file-remove_tlsoff.py
COPY file-uploader_tlsoff.py /testSDK/file-uploader_tlsoff.py
COPY create-bucket_tlsoff.py /testSDK/create-bucket_tlsoff.py
RUN chmod 777 /testSDK/file-uploader.py
RUN chmod 777 /testSDK/file-uploader_tlsoff.py
RUN chmod 777 /testSDK/create-bucket_tlsoff.py
RUN chmod 777 /testSDK/file-remove_tlsoff.py
RUN cd /root
RUN zypper -n install git
RUN git clone https://github.com/wasabi-tech/s3-benchmark.git
RUN zypper -n install go
RUN mkdir ~/go_proj
RUN pip install --no-cache-dir --upgrade pip  \
	&& pip install --no-cache-dir minio
USER root
CMD ["/bin/sh", "-c", "sleep 1d"]

