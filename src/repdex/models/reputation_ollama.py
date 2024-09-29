from typing import List, Optional

from hyfi.composer import BaseModel
from langchain.output_parsers import PydanticOutputParser
from langchain.prompts import ChatPromptTemplate
from langchain_community.chat_models import ChatOllama
from langchain_core.pydantic_v1 import BaseModel as BaseModelV1
from langchain_core.pydantic_v1 import Field as FieldV1

from repdex.llms import ChatOllamaModel
from repdex.models.reputation import ReputationDetails
from repdex.models.tests import test_input


class ReputationExtractor(BaseModel):
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

    def extract(self, input_text: str) -> ReputationDetails:
        return self.chain.invoke({"text": input_text})

    def _create_output_parser(self) -> PydanticOutputParser:
        return PydanticOutputParser(pydantic_object=ReputationDetails)

    def _create_prompt(self):
        reputation_template = """
        Your goal is to extract the details of a reputation from the given text.

        {format_instructions}

        text: {text}
        """
        format_instructions = self.output_parser.get_format_instructions()
        return ChatPromptTemplate.from_template(
            template=reputation_template,
            partial_variables={"format_instructions": format_instructions},
        )


def main():
    extractor = ReputationExtractor()
    print(test_input)
    result = extractor.extract(test_input)
    print(result)


if __name__ == "__main__":
    main()
