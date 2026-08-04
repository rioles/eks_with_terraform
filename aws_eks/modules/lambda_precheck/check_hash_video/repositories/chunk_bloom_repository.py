import os
import redis
from utils.secret_manager import get_redis_password

class ChunkBloomRepository:
    """Repository handler for managing the probabilistic Bloom Filter on Valkey."""

    BLOOM_KEY = 'bloom:chunks'

    def __init__(self):
        self.client = redis.Redis(
            host=os.environ['REDIS_HOST'],
            port=int(os.environ.get('REDIS_PORT', 6379)),
            password=get_redis_password(),
            ssl=True,
            ssl_cert_reqs=None
        )
        self._ensure_filter_exists()

    def _ensure_filter_exists(self):
        """Initialize the Bloom Filter structure within the Valkey cluster instance.

        Raises:
            redis.ResponseError: If the reservation command fails for reasons 
                other than the key already existing.
        """
        try:
            self.client.execute_command('BF.RESERVE', self.BLOOM_KEY, '0.01', 1_000_000)
            print("✅ Bloom Filter initialized or already exists on Valkey.")
        except redis.ResponseError as e:
            error_msg = str(e).lower()
            if 'item exists' in error_msg or 'busykey' in error_msg:
                pass  
            else:
                print(f"⚠️ Unexpected BF.RESERVE error: {e}")
                raise

    def exists(self, chunk_hash: str) -> bool:
        """Check if a video chunk hash is probably present in the Bloom Filter.

        Args:
            chunk_hash (str): The hexadecimal hash of the chunk to verify.

        Returns:
            bool: True if the element might exist, False if it definitely does not.
        """
        try:
            return self.client.execute_command('BF.EXISTS', self.BLOOM_KEY, chunk_hash) == 1
        except Exception as e:
            print(f"❌ Valkey Bloom error on exists({chunk_hash}): {e}")
            return True  

    def add(self, chunk_hash: str) -> None:
        """Add a verified chunk hash to the Bloom Filter data structure.

        Args:
            chunk_hash (str): The hexadecimal hash of the chunk to store.
        """
        try:
            self.client.execute_command('BF.ADD', self.BLOOM_KEY, chunk_hash)
        except Exception as e:
            print(f"❌ Valkey Bloom error on add({chunk_hash}): {e}")
            raise

    def clear_filter(self) -> None:
        """Completely flush the Bloom Filter key from the cache cluster database."""
        try:
            self.client.delete(self.BLOOM_KEY)
            print("扫 Bloom Filter cleared successfully from Redis.")
        except Exception as e:
            print(f"❌ Error while deleting the Bloom Filter: {e}")
            raise
