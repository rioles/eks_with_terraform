import os
import json
import time
import urllib.request
import urllib.parse
import urllib.error

def get_redis_password():
    secret_arn = os.environ.get('REDIS_SECRET_ARN')
    if not secret_arn:
        raise ValueError("L'environnement REDIS_SECRET_ARN n'est pas défini par Terraform.")
    
    port = os.environ.get('PARAMETERS_SECRETS_EXTENSION_HTTP_PORT', '2773')
    encoded_arn = urllib.parse.quote(secret_arn, safe='')
    url = f"http://localhost:{port}/secretsmanager/get?secretId={encoded_arn}"
    headers = {
        "X-Aws-Parameters-Secrets-Token": os.environ.get("AWS_SESSION_TOKEN")
    }

    max_retries = 5
    for attempt in range(max_retries):
        req = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode("utf-8"))
                return result.get("SecretString")
        except urllib.error.HTTPError as e:
            error_body = e.read().decode()
            if "not ready" in error_body and attempt < max_retries - 1:
                wait_time = 0.5 * (attempt + 1)  # 0.5s, 1s, 1.5s, 2s...
                print(f"⏳ Extension pas prête, retry dans {wait_time}s (tentative {attempt + 1}/{max_retries})")
                time.sleep(wait_time)
                continue
            print(f"❌ Détail erreur HTTP {e.code}: {error_body}")
            raise
        except Exception as e:
            print(f"❌ Erreur lors de la récupération du secret via le Layer Extension: {e}")
            raise
    
    raise RuntimeError("L'extension Secrets Manager n'est jamais devenue prête après plusieurs tentatives.")
