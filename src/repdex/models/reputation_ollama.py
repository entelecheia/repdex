from typing import List, Optional

from hyfi.composer import BaseModel
from langchain.output_parsers import PydanticOutputParser
from langchain.prompts import ChatPromptTemplate
from langchain_community.chat_models import ChatOllama

from repdex.llms import ChatOllamaModel
from repdex.models.reputation import ReputationDetails, ReputationAspect
from repdex.models.tests import test_input


class ReputationExtractorOllama(BaseModel):
    _config_group_: str = "/model"
    _config_name_: str = "ReputationExtractorOllama"

    llm_model: ChatOllamaModel = ChatOllamaModel()

    _engine_: Optional[ChatOllama] = None
    _output_parser_: Optional[PydanticOutputParser] = None
    _prompt_: Optional[ChatPromptTemplate] = None

    def initialize(self):
        self._engine_ = self.llm_model.engine
        self._output_parser_ = self._create_output_parser()
        self._prompt_ = self._create_prompt()

    @property
    def engine(self) -> ChatOllama:
        if self._engine_ is None:
            self.initialize()
        return self._engine_

    @property
    def output_parser(self) -> PydanticOutputParser:
        if self._output_parser_ is None:
            self.initialize()
        return self._output_parser_

    @property
    def prompt(self) -> ChatPromptTemplate:
        if self._prompt_ is None:
            self.initialize()
        return self._prompt_

    @property
    def chain(self):
        return self.prompt | self.engine | self.output_parser

    def _create_output_parser(self) -> PydanticOutputParser:
        return PydanticOutputParser(pydantic_object=ReputationDetails)

    def _create_prompt(self):
        reputation_template = """
        Analyze the given text and extract detailed information about the reputation of a specific company and its owner. Focus on the following aspects: "management", "workplace", "product & service", "social", "financial", and "owner".

        The "owner" aspect concerns the personal reputation of the individual who owns the majority of the company's shares.

        Identify all aspect terms and their corresponding opinion terms within the text. Aspect terms are sentences or phrases that describe specific characteristics or attributes of the company or the owner. Opinion terms are adjectives or phrases that express distinct sentiments.

        Determine the sentiment polarity for each aspect, which can be "positive", "negative", or "neutral".

        Do not include performance or trading of stocks or supply and demand of stock market in any aspect. Financial performance should not be classified as a "product & service" aspect.

        Also, identify the company name.

        Format your response as a list of dictionaries, like this:
        [{{"company": "company name", "aspect": "management", "aspect_terms": ["management"], "opinion_terms": ["good"], "sentiment": "positive"}}, ...]

        If the text doesn't provide any relevant information about a company or its owner, or doesn't contain any necessary aspect or opinion terms, return an empty list, [].

        {format_instructions}

        text: {text}
        """
        format_instructions = self.output_parser.get_format_instructions()
        return ChatPromptTemplate.from_template(
            template=reputation_template,
            partial_variables={"format_instructions": format_instructions},
        )

    def extract(self, input_text: str) -> List[ReputationAspect]:
        result = self.chain.invoke({"text": input_text})
        return result.aspects or []


def main():
    extractor = ReputationExtractorOllama()
    print(test_input)
    result = extractor.extract(test_input)
    print(result)


if __name__ == "__main__":
    main()
