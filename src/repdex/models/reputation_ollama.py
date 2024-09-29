from repdex.llms import ChatOllamaModel
from repdex.models.reputation_base import BaseReputationExtractor
from repdex.models.tests import test_input


class ReputationExtractorOllama(BaseReputationExtractor):
    _config_name_: str = "ReputationExtractorOllama"
    llm_model: ChatOllamaModel = ChatOllamaModel()


def main():
    extractor = ReputationExtractorOllama()
    print(test_input)
    result = extractor.extract(test_input)
    print(result)


if __name__ == "__main__":
    main()
