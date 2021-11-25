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
    client.remove_object("testing", "uploadedFile")

    print(
        "successfully removed (tls=off)"
    )


if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
