from minio import Minio
from minio.error import S3Error
import os

def main():
    os.environ["SSL_CERT_FILE"] ="/etc/pki/trust/anchors/root_ca.pem"
    client = Minio(
        "eric-data-object-storage-mn:9000",
        access_key="AKIAIOSFODNN7EXAMPLE",
        secret_key="wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY",
        secure=False
    )
    # Make 'asiatrip' bucket if not exist.
    found = client.bucket_exists("testing")
    if not found:
        client.make_bucket("testing")
    else:
        print("Bucket 'testing' already exists")

if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
