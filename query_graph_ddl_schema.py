import os
from typing import Any

from baml_client.sync_client import b
from utils import KuzuDatabaseManager, get_schema_ddl, prune_ddl_schema

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


def run_pruned_ddl_schema_query(db_manager: KuzuDatabaseManager, question: str) -> None:
    ddl_schema = get_schema_ddl()
    ddl_schema_pruned = prune_ddl_schema(question, ddl_schema)
    print(f"Pruned DDL schema:\n{ddl_schema_pruned}\n---")
    results = run_query(db_manager, ddl_schema_pruned, question)
    print(results)


if __name__ == "__main__":
    DB_NAME = "ldbc_1.kuzu"
    db_manager = KuzuDatabaseManager(DB_NAME)
    questions = [
        "What are the first/last names of people who live in 'Glasgow', and are interested in the tag 'Napoleon'?",
    ]
    for question in questions:
        run_pruned_ddl_schema_query(db_manager, question)
