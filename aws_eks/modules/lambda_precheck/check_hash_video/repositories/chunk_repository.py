import os
import boto3
from botocore.exceptions import ClientError

class ChunkRepository:
    """Repository handler for querying video chunk metadata from Amazon DynamoDB."""

    BATCH_SIZE = 100  

    def __init__(self):
        self.table_name = os.environ['DYNAMODB_TABLE']
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(self.table_name)

    def get_urls(self, hashes: list) -> dict:
        """Query storage tracking entries for a collection of chunk hashes.

        Args:
            hashes (list): Collection of unique hash identifiers to look up.

        Returns:
            dict: Mapping layout containing found records in a {hash: s3_url} format.
        """
        if not hashes:
            return {}

        result = {}
        for i in range(0, len(hashes), self.BATCH_SIZE):
            batch = hashes[i:i + self.BATCH_SIZE]
            batch_result = self._fetch_batch(batch)
            result.update(batch_result)

        return result

    def _fetch_batch(self, hashes: list) -> dict:
        """Perform a single structural batch lookup operation on DynamoDB.

        Args:
            hashes (list): A list of chunk hashes containing up to 100 elements.

        Returns:
            dict: Resolved mapping entries recovered from the database response.
        """
        keys = [{'chunk_hash': h} for h in hashes]

        try:
            response = self.table.meta.client.batch_get_item(
                RequestItems={
                    self.table_name: {
                        'Keys': keys,
                        'ProjectionExpression': 'chunk_hash, s3_url'
                    }
                }
            )
        except ClientError as e:
            print(f"❌ DynamoDB batch_get_item error: {e}")
            raise

        unprocessed = response.get('UnprocessedKeys', {})
        if unprocessed:
            print(f"⚠️ UnprocessedKeys detected: {len(unprocessed)} items left unprocessed.")

        items = response.get('Responses', {}).get(self.table_name, [])
        return {item['chunk_hash']: item['s3_url'] for item in items}
