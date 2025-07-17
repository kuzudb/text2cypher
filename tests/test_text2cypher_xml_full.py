from typing import Any

import pytest

from baml_client.sync_client import b
from tests.test_data import suite_1a, suite_1b, suite_1c
from utils import KuzuDatabaseManager

DB_NAME = "ldbc_1.kuzu"


@pytest.fixture
def db_manager():
    manager = KuzuDatabaseManager(DB_NAME)
    yield manager


def run_query(
    db_manager: KuzuDatabaseManager, schema: str, question: str
) -> tuple[str, list[Any] | None]:
    """
    Run a query on the database.
    """
    response = b.Text2Cypher(question, schema)
    query = response.cypher
    try:
        # Run the query on the database
        result = db_manager.conn.execute(query)
        results = [item for row in result for item in row]
    except RuntimeError as e:
        print(f"Error running query: {e}")
        results = None
    return (query, results)


def _run_test_suite(db_manager, schema, test_cases, expected_boolean=False):
    for q in test_cases:
        query, results = run_query(db_manager, schema, q["question"])
        expected = set(q["expected_values"])
        found = set()
        if expected_boolean:
            # Run binary answer question prompt on the results
            binary_answer = b.AnswerQuestionBinary(q["question"], str(results))
            found.add( binary_answer)
        else:
            if results is not None:
                for v in results:
                    if isinstance(v, list):
                        found.update(v)
                    else:
                        found.add(v)
        assert expected <= found, (
            f"Expected all of {expected} in result {found} for question: {q['question']}\n"
            f"Cypher query: {query}"
        )


@pytest.mark.parametrize("q", suite_1a)
def test_suite_1a_xml(q, db_manager):
    schema = db_manager.get_schema_dict
    schema_xml = db_manager.get_schema_xml(schema)
    _run_test_suite(db_manager, schema_xml, [q])


@pytest.mark.parametrize("q", suite_1b)
def test_suite_1b_xml(q, db_manager):
    schema = db_manager.get_schema_dict
    schema_xml = db_manager.get_schema_xml(schema)
    _run_test_suite(db_manager, schema_xml, [q])


@pytest.mark.parametrize("q", suite_1c)
def test_suite_1c_xml(q, db_manager):
    schema = db_manager.get_schema_dict
    schema_xml = db_manager.get_schema_xml(schema)
    _run_test_suite(db_manager, schema_xml, [q], expected_boolean=True)
