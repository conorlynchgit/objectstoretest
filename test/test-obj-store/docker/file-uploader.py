from minio import Minio
from minio.error import S3Error
import os

def main():
    # before running script , create file (or whatever size) called /fileToUpload.txt
    # e.g for 100MB file .. head -c 100MB /dev/urandom >/fileToUpload.txt
    filetoupload="/fileToUpload.txt"



    os.environ["SSL_CERT_FILE"] ="/etc/pki/trust/anchors/root_ca.pem"
    dns_name=os.environ["STORAGE_SERVER_DNS"]
    dns_name=dns_name+":9000"
    bucketname=os.environ["BUCKET_NAME"]
    client = Minio(
        dns_name,
        access_key=os.environ["MINIO_ACCESS_KEY"],
        secret_key=os.environ["MINIO_SECRET_KEY"],
        secure=False
    )

    found = client.bucket_exists(bucketname)
    if not found:
        client.make_bucket(bucketname)
    else:
        print("Bucket", bucketname ,"already exists")

    client.fput_object(
        bucketname, "uploadedFile", filetoupload, part_size=0, num_parallel_uploads=3
    )
    print(
        "successfully uploaded "
    )


if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
