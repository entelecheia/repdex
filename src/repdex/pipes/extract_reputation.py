import logging
import uuid
from typing import Dict, List

from hyfi import HyFI
from tqdm import tqdm

from repdex.models.reputation import ReputationExtractor

logger = logging.getLogger(__name__)


def assign_uuids(data: List[Dict]) -> List[Dict]:
    for item in data:
        if "uuid" not in item:
            item["uuid"] = str(uuid.uuid4())
    return data


def extract_reputation_details(data: List[Dict], extractor: ReputationExtractor) -> List[Dict]:
    extracted_data = []
    for item in tqdm(data):
        try:
            text = item["content"]
            if "reputation" not in text.lower():
                logger.info(
                    "No reputation-related content found in item with UUID: %s",
                    item["uuid"],
                )
                continue
            logger.info("Extracting reputation details from item with UUID: %s", item["uuid"])
            reputation_details = extractor.extract(text)
            if not reputation_details.has_reputation:
                logger.info("No reputation found in item with UUID: %s", item["uuid"])
                continue
            logger.info("Lawsuit found in item with UUID: %s", item["uuid"])
            extracted_item = {
                "uuid": item["uuid"],
                "has_reputation": reputation_details.has_reputation,
                "claimant": reputation_details.claimant,
                "defendant": reputation_details.defendant,
                "case_summary": reputation_details.case_summary,
                "case_date": reputation_details.case_date,
                "other_details": reputation_details.other_details,
            }
            extracted_data.append(extracted_item)
        except Exception as e:
            logger.error("Error extracting reputation details for UUID: %s", item["uuid"])
            logger.error("Error: %s", e)
    return extracted_data


def extract(
    scraped_data_file: str = "scraped_data.json",
    extracted_data_file: str = "extracted_reputation_data.json",
):
    extractor = ReputationExtractor()

    # Load scraped press release data
    logger.info("Loading scraped data from %s", scraped_data_file)
    scraped_data = HyFI.load_jsonl(scraped_data_file)

    # Assign UUIDs to press releases
    data_with_uuids = assign_uuids(scraped_data)
    HyFI.save_jsonl(data_with_uuids, scraped_data_file)
    logger.info(
        "Assigned UUIDs to %s press releases and saved to %s",
        len(data_with_uuids),
        scraped_data_file,
    )

    # Apply ReputationExtractor to press releases
    extracted_data = extract_reputation_details(data_with_uuids, extractor)

    # Store extracted reputation information
    HyFI.save_jsonl(extracted_data, extracted_data_file)
    logger.info(
        "Saved %s extracted reputation details to %s",
        len(extracted_data),
        extracted_data_file,
    )

    logger.info("Lawsuit extraction completed.")
