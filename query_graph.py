import os
from typing import Any

from baml_client.sync_client import b
from utils import KuzuDatabaseManager, prune_json_schema

os.environ["BAML_LOG"] = "WARN"


def run_query(
    db_manager: KuzuDatabaseManager, schema: str, question: str
) -> tuple[str, list[Any] | None]:
    """
    Run a query synchronously on the database.
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


# Run pruned schema queries


def run_prune_json_schema_query(db_manager: KuzuDatabaseManager, question: str) -> None:
    schema_pruned = prune_json_schema(db_manager, question)
    results = run_query(db_manager, str(schema_pruned), question)
    print(results)


def run_prune_xml_schema_query(db_manager: KuzuDatabaseManager, question: str) -> None:
    schema_pruned = prune_json_schema(db_manager, question)
    schema_pruned_xml = db_manager.get_schema_xml(schema_pruned)
    results = run_query(db_manager, schema_pruned_xml, question)
    print(results)


def run_prune_yaml_schema_query(db_manager: KuzuDatabaseManager, question: str) -> None:
    schema_pruned = prune_json_schema(db_manager, question)
    schema_pruned_yaml = db_manager.get_schema_yaml(schema_pruned)
    results = run_query(db_manager, schema_pruned_yaml, question)
    print(results)


# Run regular schema queries


def run_json_schema_query(db_manager: KuzuDatabaseManager, question: str) -> None:
    schema = db_manager.get_schema_dict
    results = run_query(db_manager, str(schema), question)
    print(results)


def run_xml_schema_query(db_manager: KuzuDatabaseManager, question: str) -> None:
    schema = db_manager.get_schema_dict
    schema_xml = db_manager.get_schema_xml(schema)
    results = run_query(db_manager, schema_xml, question)
    print(results)


def run_yaml_schema_query(db_manager: KuzuDatabaseManager, question: str) -> None:
    schema = db_manager.get_schema_dict
    schema_yaml = db_manager.get_schema_yaml(schema)
    results = run_query(db_manager, schema_yaml, question)
    print(results)


if __name__ == "__main__":
    DB_NAME = "ldbc_1.kuzu"
    db_manager = KuzuDatabaseManager(DB_NAME)
    questions = [
        "What are the first/last names of people who live in 'Glasgow', and are interested in the tag 'Napoleon'?",
    ]
    for question in questions:
        # run_xml_schema_query(db_manager, question)
        run_prune_xml_schema_query(db_manager, question)
