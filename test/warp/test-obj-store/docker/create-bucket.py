from minio import Minio
from minio.error import S3Error
import os
import distutils.util
def main():
    os.environ["SSL_CERT_FILE"] ="/etc/pki/trust/anchors/cacertbundle.pem"
    dns_name=os.environ["STORAGE_SERVER_DNS"]
    dns_name=dns_name+":9000"
    bucketname=os.environ["BUCKET_NAME"]
    client = Minio(
        dns_name,
        access_key=os.environ["MINIO_ACCESS_KEY"],
        secret_key=os.environ["MINIO_SECRET_KEY"],
        secure=distutils.util.strtobool(os.environ["TLS_ENABLED"])
    )

    found = client.bucket_exists(bucketname)
    if not found:
        client.make_bucket(bucketname)
    else:
        print("Bucket", bucketname, "already exists")

if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
