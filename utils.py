"""
Kuzu database manager and schema compression utilities.
"""

import os
import re
from textwrap import dedent
from typing import Any

import kuzu

from baml_client.sync_client import b

os.environ["BAML_LOG"] = "WARN"

# --- Kuzu Database ---


class KuzuDatabaseManager:
    """Manages Kuzu database connection and schema retrieval."""

    def __init__(self, db_path: str = "ex_kuzu_db"):
        self.db_path = db_path
        self.db = kuzu.Database(db_path, read_only=True)
        self.conn = kuzu.Connection(self.db)

    @property
    def get_schema_dict(self) -> dict[str, list[dict]]:
        response = self.conn.execute("CALL SHOW_TABLES() WHERE type = 'NODE' RETURN *;")
        nodes = [row[1] for row in response]  # type: ignore
        response = self.conn.execute("CALL SHOW_TABLES() WHERE type = 'REL' RETURN *;")
        rel_tables = [row[1] for row in response]  # type: ignore
        relationships = []
        for tbl_name in rel_tables:
            response = self.conn.execute(f"CALL SHOW_CONNECTION('{tbl_name}') RETURN *;")
            for row in response:
                relationships.append({"name": tbl_name, "from": row[0], "to": row[1]})  # type: ignore
        schema = {"nodes": [], "edges": []}

        for node in nodes:
            node_schema = {"label": node, "properties": []}
            node_properties = self.conn.execute(f"CALL TABLE_INFO('{node}') RETURN *;")
            for row in node_properties:  # type: ignore
                node_schema["properties"].append({"name": row[1], "type": row[2]})  # type: ignore
            schema["nodes"].append(node_schema)

        for rel in relationships:
            edge = {
                "label": rel["name"],
                "from": rel["from"],
                "to": rel["to"],
                "properties": [],
            }
            rel_properties = self.conn.execute(f"""CALL TABLE_INFO('{rel["name"]}') RETURN *;""")
            for row in rel_properties:  # type: ignore
                edge["properties"].append({"name": row[1], "type": row[2]})  # type: ignore
            schema["edges"].append(edge)

        return schema

    def get_schema_xml(self, schema: dict[str, list[dict]]) -> str:
        """Convert the JSON schema into XML format with structure, nodes, and relationships."""
        # Structure section: just relationship structure
        structure_lines = []
        for edge in schema["edges"]:
            structure_lines.append(
                f'  <rel label="{edge["label"]}" from="{edge["from"]}" to="{edge["to"]}" />'
            )
        structure_xml = f"<structure>\n{chr(10).join(structure_lines)}\n</structure>"

        # Nodes section: node label and properties
        node_lines = []
        for node in schema["nodes"]:
            prop_lines = [
                f'    <property name="{prop["name"]}" type="{prop["type"]}" />'
                for prop in node["properties"]
            ]
            node_lines.append(
                f'  <node label="{node["label"]}">\n' + "\n".join(prop_lines) + "\n  </node>"
            )
        nodes_xml = f"<nodes>\n{chr(10).join(node_lines)}\n</nodes>"

        # Relationships section: edge label and properties (if any)
        rel_lines = []
        for edge in schema["edges"]:
            if edge.get("properties"):
                prop_lines = [
                    f'    <property name="{prop["name"]}" type="{prop["type"]}" />'
                    for prop in edge["properties"]
                ]
                rel_lines.append(
                    f'  <rel label="{edge["label"]}">\n' + "\n".join(prop_lines) + "\n  </rel>"
                )
            else:
                rel_lines.append(f'  <rel label="{edge["label"]}" />')
        relationships_xml = f"<relationships>\n{chr(10).join(rel_lines)}\n</relationships>"

        # Combine all sections
        return f"{structure_xml}\n{nodes_xml}\n{relationships_xml}"

    def get_schema_yaml(self, schema: dict[str, list[dict]]) -> str:
        """Convert the JSON schema into YAML format."""
        # Structure section: just relationship structure
        structure_lines = [
            f"  - label: {edge['label']}\n    from: {edge['from']}\n    to: {edge['to']}"
            for edge in schema["edges"]
        ]
        structure_yaml = f"structure:\n{chr(10).join(structure_lines)}"

        # Nodes section: node label and properties
        node_lines = []
        for node in schema["nodes"]:
            prop_lines = [
                f"      - name: {prop['name']}\n        type: {prop['type']}"
                for prop in node["properties"]
            ]
            node_lines.append(
                f"  - label: {node['label']}\n    properties:\n" + "\n".join(prop_lines)
            )
        nodes_yaml = f"nodes:\n{chr(10).join(node_lines)}"

        # Relationships section: edge label and properties (if any)
        rel_lines = []
        for edge in schema["edges"]:
            if edge.get("properties"):
                prop_lines = [
                    f"      - name: {prop['name']}\n        type: {prop['type']}"
                    for prop in edge["properties"]
                ]
                rel_lines.append(
                    f"  - label: {edge['label']}\n    properties:\n" + "\n".join(prop_lines)
                )
            else:
                rel_lines.append(f"  - label: {edge['label']}")
        relationships_yaml = f"relationships:\n{chr(10).join(rel_lines)}"

        # Combine all sections
        return f"{structure_yaml}\n{nodes_yaml}\n{relationships_yaml}"


# --- Schema pruning ---


def rename_from_(obj: Any) -> Any:
    if isinstance(obj, dict):
        return {("from" if k == "from_" else k): rename_from_(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [rename_from_(item) for item in obj]
    else:
        return obj


def prune_json_schema(db_manager: KuzuDatabaseManager, question: str) -> dict[str, Any]:
    """
    Prune the schema based on the question, using a BAML prompt.
    """
    schema = db_manager.get_schema_dict
    schema_pruned = b.PruneSchema(question, str(schema)).model_dump()
    print(schema_pruned)
    # Rename the "from_" field to "from" because of Pydantic reserved keyword conflict
    schema_pruned = rename_from_(schema_pruned)
    return schema_pruned


def get_schema_ddl() -> str:
    """
    Get the schema of the database in DDL format.
    """
    ddl = None
    with open("./etl/schema.cypher", "r") as f:
        ddl = f.read()
    assert ddl is not None, "Please point to the correct path to the schema.cypher file."
    # Remove the `MANY_*` and `ONE_*` from the DDL
    ddl = re.sub(r",\s+MANY_\w+", "", ddl)
    ddl = re.sub(r",\s+ONE_\w+", "", ddl)
    return ddl


def prune_ddl_schema(question: str, ddl_schema: str) -> str:
    """
    Prune the Kuzu DDL schema based on the question.
    """
    response = b.PruneSchemaDDL(question, ddl_schema)
    if not response.ddl:
        raise ValueError("No DDL schema returned!")
    return response.ddl


# --- Schema Compression ---


class SchemaCompressor:
    """
    Compresses a graph schema into a compact string representation based on mappings.
    The aim is to reduce the number of tokens required to represent a given property graph schema
    to an LLM that does Text2Cypher.

    The compression is done by mapping the properties, node labels, and relationships to integers.
    The mapping is created from a JSON representation of the graph schema as follows:
    - Properties are mapped to integers in the order they appear in the schema.
    - Node labels are mapped to integers in the order they appear in the schema.
    - Relationships are mapped to integers in the order they appear in the schema.

    The compressed schema is then represented as a string of the form:
    <src_id>-[<rel_id>]->{dst_id} : {src_props_str} -{rel_props_str}-> {dst_props_str}

    where:
    - <src_id> is the integer mapping of the source node label.
    - <rel_id> is the integer mapping of the relationship label.
    - {dst_id} is the integer mapping of the destination node label.
    - {src_props_str} is the string representation of the source node properties.
    - {rel_props_str} is the string representation of the relationship properties.
    """

    def __init__(self, db_manager: KuzuDatabaseManager):
        self.schema = db_manager.get_schema_dict
        self.property_mapping = {}
        self.node_label_mapping = {}
        self.relationship_mapping = {}
        self.generate_mappings()

    def _generate_node_mappings(self):
        """Generate mappings for node labels and their properties."""
        node_counter = 1
        for node in self.schema.get("nodes", []):
            label = node.get("label")
            if label not in self.node_label_mapping:
                self.node_label_mapping[label] = node_counter
                node_counter += 1
            for prop in node.get("properties", []):
                pname = prop.get("name")
                if pname not in self.property_mapping:
                    self.property_mapping[pname] = len(self.property_mapping) + 1

    def _generate_relationship_mappings(self):
        """Generate mappings for relationships and their properties."""
        relationship_counter = 1
        for edge in self.schema.get("edges", []):
            rel_label = edge.get("label")
            if rel_label not in self.relationship_mapping:
                self.relationship_mapping[rel_label] = relationship_counter
                relationship_counter += 1
            for prop in edge.get("properties", []):
                pname = prop.get("name")
                if pname not in self.property_mapping:
                    self.property_mapping[pname] = len(self.property_mapping) + 1

    def generate_mappings(self) -> tuple[dict[str, int], dict[str, int], dict[str, int]]:
        """Generate all mappings for properties, node labels, and relationships."""
        self._generate_node_mappings()
        self._generate_relationship_mappings()
        return self.node_label_mapping, self.relationship_mapping, self.property_mapping

    def get_format_str(self) -> str:
        """Return a string showing the format of the compressed schema."""
        format_str = dedent("""
        ## [FORMAT]
        ```
        A-[R]->B : {A_props} -[R_props]-> {B_props}
        ```

        - A, B = node label IDs (see [NODES])
        - R = relationship type ID (see [RELATIONSHIPS])
        - {A_props} = set of property key IDs found on node A (see [PROPERTIES])
        - {R_props} = set of property key IDs found on the relationship
        - {B_props} = set of property key IDs found on node B

        Use the map provided to decode IDs from the compressed schema.
        """)
        return format_str

    def get_mapping_str(self) -> str:
        """Return a consolidated string showing all mappings for nodes, relationships, and properties."""
        # Sort mappings by their ID values
        sorted_nodes = sorted(self.node_label_mapping.items(), key=lambda x: x[1])
        sorted_relationships = sorted(self.relationship_mapping.items(), key=lambda x: x[1])
        sorted_properties = sorted(self.property_mapping.items(), key=lambda x: x[1])

        # Build the output string
        lines = []

        # Nodes section
        lines.append("## [NODES]")
        lines.append("```")
        for label, node_id in sorted_nodes:
            lines.append(f"{node_id} = {label}")
        lines.append("```")
        lines.append("")

        # Relationships section
        lines.append("## [RELATIONSHIPS]")
        lines.append("```")
        for rel_label, rel_id in sorted_relationships:
            lines.append(f"{rel_id} = {rel_label}")
        lines.append("```")
        lines.append("")

        # Properties section
        lines.append("## [PROPERTIES]")
        lines.append("```")
        for prop_name, prop_id in sorted_properties:
            lines.append(f"{prop_id} = {prop_name}")
        lines.append("```")

        return "\n".join(lines)

    def compress_schema(self) -> str:
        """Compress the schema into a compact string representation."""
        # Build a mapping of node labels to their property ID sets
        node_props = {}
        for node in self.schema.get("nodes", []):
            label = node.get("label")
            if label in self.node_label_mapping:
                props = set()
                for prop in node.get("properties", []):
                    pname = prop.get("name")
                    if pname in self.property_mapping:
                        props.add(self.property_mapping[pname])
                node_props[label] = sorted(props)

        lines = []
        for edge in self.schema.get("edges", []):
            rel_label = edge.get("label")
            if rel_label not in self.relationship_mapping:
                continue
            src_label = edge.get("from")
            dst_label = edge.get("to")
            if src_label not in self.node_label_mapping or dst_label not in self.node_label_mapping:
                continue
            rel_id = self.relationship_mapping[rel_label]
            src_id = self.node_label_mapping[src_label]
            dst_id = self.node_label_mapping[dst_label]
            src_props = node_props.get(src_label, [])
            dst_props = node_props.get(dst_label, [])
            rel_props = set()
            for prop in edge.get("properties", []):
                pname = prop.get("name")
                if pname in self.property_mapping:
                    rel_props.add(self.property_mapping[pname])
            src_props_str = f'{{{",".join(str(x) for x in src_props)}}}'
            dst_props_str = f'{{{",".join(str(x) for x in dst_props)}}}'
            rel_props_list = sorted(rel_props)
            if rel_props_list:
                rel_props_str = f"[{','.join(str(x) for x in rel_props_list)}]"
            else:
                rel_props_str = "[]"
            line = f"{src_id}-[{rel_id}]->{dst_id} : {src_props_str} -{rel_props_str}-> {dst_props_str}"
            lines.append(line)

        # Combine the compressed schema with the mappings
        mapping_str = self.get_mapping_str()
        format_str = self.get_format_str()
        compressed_schema_str = f'{"## [COMPRESSED_SCHEMA]\n\n"}{chr(10).join(lines)}'
        compressed_schema_str = f"{compressed_schema_str}\n\n{mapping_str}\n\n{format_str}"
        return compressed_schema_str


def main() -> None:
    db_manager = KuzuDatabaseManager("ldbc_1.kuzu")
    schema = db_manager.get_schema_dict
    print(schema, "\n---")
    print(db_manager.get_schema_xml(schema), "\n---")
    # print(db_manager.get_schema_yaml(schema), "\n---")

    # compressor = SchemaCompressor(db_manager)
    # compressed_schema_str = compressor.compress_schema()
    # print(compressed_schema_str)


if __name__ == "__main__":
    main()
