import uuid6
from repositories.chunk_bloom_repository import ChunkBloomRepository
from repositories.chunk_repository import ChunkRepository

class ChunkService:
    """Service layer responsible for managing video chunk logic and deduplication."""

    def __init__(self):
        self.bloom_repo = ChunkBloomRepository()  
        self.chunk_repo = ChunkRepository()

    def check_chunks(self, hashes: list) -> dict:
        """Check provided hashes against the Bloom Filter and verify with the DB.

        This function filters out definitely new chunks using a fast local Bloom 
        Filter lookup, then resolves any potential false positives by querying 
        the primary storage database.

        Args:
            hashes (list): A list of string hashes representing the video chunks 
                to verify.

        Returns:
            dict: A dictionary containing:
                - 'uploadId' (str): A unique UUIDv7 identifying this session.
                - 'existingChunks' (dict): A mapping of {hash: s3_url} for 
                  chunks that already exist in the database.
        """
        upload_id = str(uuid6.uuid7())

        probably_present = [h for h in hashes if self.bloom_repo.exists(h)]

        existing_chunks = {}
        if probably_present:
            existing_chunks = self.chunk_repo.get_urls(probably_present)

        return {
            'uploadId': upload_id,
            'existingChunks': existing_chunks
        }
