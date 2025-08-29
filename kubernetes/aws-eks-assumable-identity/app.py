import os
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
import requests
import base64
import sys
import json
import argparse

def aws_token(identity: str) -> str:
  """
  Use AWS credentials in the environment to sign a HTTP request and use it to
  construct a token supported by the Chainguard platform.
  """

  # Prepare a GetCallerIdentity request.
  request = AWSRequest(
      method="POST",
      url="https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
      headers={
          "Host": "sts.amazonaws.com",
          "Accept": "application/json",
          "Chainguard-Audience": "https://issuer.enforce.dev",
          "Chainguard-Identity": identity,
      },
  )

  # Sign AWS GetCallerIdentity request using AWS credentials
  SigV4Auth(boto3.Session().get_credentials(), "sts", "us-east-1").add_auth(request)

  prepared = request.prepare()

  # Serialize GetCallerIdentity to HTTP/1.1 wire format. This will be sent to
  # Chainguard STS exchange endpoint as proof of AWS identity instead sending
  # to AWS.
  serialized = f"{prepared.method} {prepared.url} HTTP/1.1\r\n"
  for k, v in request.headers.items():
      serialized += f"{k}: {v}\r\n"
  serialized += f"\r\n\r\n"

  return base64.urlsafe_b64encode(serialized.encode("utf-8")).decode("utf-8")

def exchange(token: str, identity: str) -> str:
  """
  Exchange a token with the Chainguard platform.
  """

  response = requests.request(
    method='POST',
    url='https://issuer.enforce.dev/sts/exchange',
    params={
      'aud': 'cgr.dev',
      'identity': identity,
    },
    headers={
      'Authorization': f"Bearer {token}", 
      'User-Agent': 'pull-secret-updater/0.0.0',
      'Accept': '*/*',
    },
  )
  if response.status_code != 200:
      raise Exception(f"{response.text}") 

  return json.loads(response.text)["token"]

def update_pull_secrets(core_v1: client.CoreV1Api, token: str, secret_name: str):
  """
  Create/update secrets in all namespaces with docker configuration
  containing the given token.
  """

  # Create a docker config with the identity token
  print("Constructing docker config...")
  docker_config = {
    "auths": {
      "cgr.dev": {
        "auth": base64.urlsafe_b64encode(f"_token:{token}".encode("utf-8")).decode("utf-8"),
      }
    }
  }

  # List all namespaces
  print("Listing namespaces...")
  try:
    namespace_list = core_v1.list_namespace()
    namespaces = [ns.metadata.name for ns in namespace_list.items]
  except ApiException as e:
    raise e

  # Create or update a secret in each namespace with the new docker config
  ok = True
  for ns in namespaces:
    secret = client.V1Secret(
      metadata=client.V1ObjectMeta(
          name=secret_name,
          namespace=ns,
      ),
      type='kubernetes.io/dockerconfigjson',
      data={
          '.dockerconfigjson': base64.b64encode(json.dumps(docker_config).encode("utf-8")).decode("utf-8"),
      },
    )
    print(f"Copying pull secret to {secret_name} in {ns}...")
    try:
      create_or_update_secret(core_v1, secret)
    except Exception as e:
        print(f"[error]: creating/updating {args.secret_name} in {ns}: {e}")
        ok = False

  # Tolerate errors when creating pull secrets but raise an exception at the end
  # so errors are surfaced.
  if not ok:
    raise Exception('[error]: errors encountered')

def create_or_update_secret(core_v1: client.CoreV1Api, secret: client.V1Secret):
  """
  Create a Kubernetes secret. If it already exists, update it.
  """

  try:
    # Try to fetch the existing secret
    core_v1.read_namespaced_secret(secret.metadata.name, secret.metadata.namespace)

    # If it exists, patch it
    core_v1.patch_namespaced_secret(
      name=secret.metadata.name,
      namespace=secret.metadata.namespace,
      body=secret,
    )
  except ApiException as e:
    # If it doesn't exist, create it
    if e.status == 404:
      core_v1.create_namespaced_secret(secret.metadata.namespace, secret)
    # Raise any other error
    else:
      raise e

def main():
  parser = argparse.ArgumentParser(
    description="Update pull secrets using an AWS assumable identity")
  parser.add_argument('--identity', type=str, help="The id of the identity to assume", required=True)
  parser.add_argument('--secret-name', type=str, help="The name of the pull secret", default="cgr-pull-secret")

  args = parser.parse_args()

  # Configure Kubernetes client
  try:
    config.load_kube_config()
  except:
    config.load_incluster_config()
  core_v1 = client.CoreV1Api()

  # Exchange the token for an identity token
  print(f"Assuming identity '{args.identity}' with AWS IAM credentials...")
  chainguard_token = exchange(aws_token(args.identity), args.identity)

  # Update pull secrets with the new token
  update_pull_secrets(core_v1, chainguard_token, args.secret_name)

if __name__ == "__main__":
    main()
