from minio import Minio
from minio.error import S3Error
import os

def main():
    # before running script , create file (or whatever size) called /fileToUpload.txt
    # e.g for 100MB file .. head -c 100MB /dev/urandom >/fileToUpload.txt
    filetodownload="/fileDownloaded.txt"
    os.environ["SSL_CERT_FILE"] ="/etc/pki/trust/anchors/root_ca.pem"
    client = Minio(
        "eric-data-object-storage-mn:9000",
        access_key="AKIAIOSFODNN7EXAMPLE",
        secret_key="wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY",
        secure=False
    )
    client.fget_object(
        "testing", "uploadedFile", filetodownload
    )
    print(
        "successfully downloaded (tls=off)"
    )


if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
