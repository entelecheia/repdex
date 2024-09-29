import os
import pytest
from repdex.models.reputation import ReputationExtractor
from repdex.models.tests import test_input
from repdex.llms import ChatOpenAIModel

# Skip tests if running in CI environment
skip_if_ci = pytest.mark.skipif(
    os.environ.get("CI") == "true", reason="Skipping tests in CI environment"
)


@skip_if_ci
def test_reputation_extractor_initialization():
    extractor = ReputationExtractor()
    assert extractor._config_name_ == "ReputationExtractor"
    assert isinstance(extractor.llm_model, ChatOpenAIModel)


@skip_if_ci
def test_reputation_extractor_extract():
    extractor = ReputationExtractor()
    result = extractor.extract(test_input)
    assert result is not None
    # Add more assertions based on the expected structure and content of `result`


if __name__ == "__main__":
    pytest.main()
