import os
import pytest
from repdex.models.reputation_ollama import ReputationExtractorOllama
from repdex.models.tests import test_input
from repdex.llms import ChatOllamaModel

# Skip tests if running in CI environment
skip_if_ci = pytest.mark.skipif(
    os.environ.get("CI") == "true", reason="Skipping tests in CI environment"
)


@skip_if_ci
def test_reputation_extractor_initialization():
    extractor = ReputationExtractorOllama()
    assert extractor._config_name_ == "ReputationExtractorOllama"
    assert isinstance(extractor.llm_model, ChatOllamaModel)


@skip_if_ci
def test_reputation_extractor_extract():
    extractor = ReputationExtractorOllama()
    result = extractor.extract(test_input)
    assert result is not None
    # Add more assertions based on the expected structure and content of `result`


if __name__ == "__main__":
    pytest.main()
