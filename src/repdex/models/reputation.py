from repdex.llms import ChatOpenAIModel
from repdex.models.reputation_base import BaseReputationExtractor
from repdex.models.tests import test_input


class ReputationExtractor(BaseReputationExtractor):
    _config_name_: str = "ReputationExtractor"
    llm_model: ChatOpenAIModel = ChatOpenAIModel()


def main():
    extractor = ReputationExtractor()
    print(test_input)
    result = extractor.extract(test_input)
    print(result)


if __name__ == "__main__":
    main()
