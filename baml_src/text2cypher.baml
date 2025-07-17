// --- Data models ---
class Query {
  cypher string @description("Valid Cypher query with no newlines")
}

class Node {
  label string
  properties Property[]
}

class Edge {
  label string @description("Relationship label")
  from_ string @alias("from") @description("Source node label")
  to string @description("Destination node label")
  properties Property[]
}

class Property {
  name string
  type string @description("Data type of the property")
}

class GraphSchema {
  nodes Node[]
  edges Edge[]
}

// Used only for DDL schema pruning (optional)
class PrunedSchema {
  ddl string @description("Valid DDL statement")
}


// --- Functions ---

function Text2Cypher(question: string, schema: string) -> Query {
  client OpenRouterGoogleGemini2Flash
  prompt #"
    Translate the given question into a valid Cypher query that respects the given graph schema.

    <SYNTAX>
    - Relationship directions are VERY important to the success of a query. Here's an example: If
    the relationship `hasCreator` is marked as `from` A `to` B, it means that B created A.
    - Use short, concise alphanumeric strings as names of variable bindings (e.g., `a1`, `r1`, etc.)    
    - When comparing string properties, ALWAYS do the following:
      - Lowercase the property values before comparison
      - Use the WHERE clause
      - Use the CONTAINS operator to check for presence of one substring in the other
    - DO NOT use APOC as the database does not support it.
    - For datetime queries, use the TIMESTAMP type, which combines the date and time.
    </SYNTAX>

    <RETURN_RESULTS>
    - If the result is an integer, return it as an integer (not a string).
    - When returning results, return property values rather than the entire node or relationship.
    - Do not attempt to coerce data types to number formats (e.g., integer, float) in your results.
    - NO Cypher keywords should be returned by your query.
    </RETURN_RESULTS>

    {{ _.role("user") }}

    <QUESTION>
    {{ question }}
    </QUESTION>

    <SCHEMA>
    {{ schema }}
    </SCHEMA>

    <OUTPUT_FORMAT>
    {{ ctx.output_format }}
    </OUTPUT_FORMAT>
  "#
}

function PruneSchema(question: string, schema: string) -> GraphSchema {
  client OpenRouterGoogleGemini2Flash
  prompt #"
    Understand the given labelled property graph schema and the given user question. Your task
    is to return ONLY the subset of the schema (node labels, edge labels and properties) that is
    relevant to the question.

    <INSTRUCTIONS>
    - The schema is a list of nodes and edges in a property graph.
    - The nodes are the entities in the graph.
    - The edges are the relationships between the nodes.
    - Properties of nodes and edges are their attributes, which helps answer the question.
    </INSTRUCTIONS>
Forum

    {{ _.role("user") }}
    <GRAPH_SCHEMA>
    {{ schema }}
    </GRAPH_SCHEMA>

    <QUESTION>
    {{ question }}
    </QUESTION>

    {{ ctx.output_format }}
  "#
}

function AnswerQuestionBinary(question: string, context: string) -> "Yes" | "No" {
  client OpenRouterGoogleGemini2Flash
  prompt #"
    Answer the given question based on the provided context. Here's how to answer:
    - If the context shows a count of zero, or is empty, return "No".
    - If the context shows a count of > 1, or returns a non-empty value, return "Yes".

    {{ _.role("user") }}

    <QUESTION>
    {{ question }}
    </QUESTION>

    <CONTEXT>
    {{ context }}
    </CONTEXT>

    <OUTPUT_FORMAT>
    {{ ctx.output_format }}
    </OUTPUT_FORMAT>
  "#
}

// Optional: Compressed schema

function Text2CypherCompressed(question: string, compressed_schema: string) -> Query {
  client OpenRouterGoogleGemini2Flash
  prompt #"
    Translate the given question into a valid Cypher query. You are working with a compressed
    representation of a property graph schema.
    - Each line describes a possible pattern in the schema using numerical identifiers for node labels,
      relationship types, and property keys.
    - Use the compressed schema to translate the question into a Cypher query.

    <SYNTAX>
    - Relationship directions are VERY important to the success of a query. Here's an example: If
    the relationship `hasCreator` is marked as `from` A `to` B, it means that B created A.
    - Use short, concise alphanumeric strings as names of variable bindings (e.g., `a1`, `r1`, etc.)
    - When comparing string properties, ALWAYS do the following:
      - Lowercase the property values before comparison
      - Use the WHERE clause
      - Use the CONTAINS operator to check for presence of one substring in the other
    - DO NOT use APOC as the database does not support it.
    - For datetime queries, use the TIMESTAMP type, which combines the date and time.
    </SYNTAX>

    <RETURN_RESULTS>
    - If the result is an integer, return it as an integer (not a string).
    - When returning results, return property values rather than the entire node or relationship.
    - Do not attempt to coerce data types to number formats (e.g., integer, float) in your results.
    - NO Cypher keywords should be returned by your query.
    </RETURN_RESULTS>

    {{ _.role("user") }}

    <QUESTION>
    {{ question }}
    </QUESTION>

    <SCHEMA>
    {{ compressed_schema }}
    </SCHEMA>

    <OUTPUT_FORMAT>
    {{ ctx.output_format }}
    </OUTPUT_FORMAT>
  "#
}

// Optional: Pruning DDL schema

function PruneSchemaDDL(question: string, schema: string) -> PrunedSchema {
  client OpenRouterGoogleGemini2Flash
  prompt #"
    Understand the given labelled property graph schema DDL statements and the given user question.
    Your task is to return ONLY the subset of the schema (node labels, edge labels and properties)
    and their associated data types that is relevant to the question.

    <INSTRUCTIONS>
    - `CREATE NODE TABLE` statements define the nodes in the graph.
    - `CREATE REL TABLE` statements define the relationships between the nodes.
    - Properties of nodes and relationships are defined inside the parentheses of each CREATE statement.
    </INSTRUCTIONS>


    {{ _.role("user") }}
    <GRAPH_SCHEMA>
    {{ schema }}
    </GRAPH_SCHEMA>

    <QUESTION>
    {{ question }}
    </QUESTION>

    <OUTPUT_FORMAT>
    {{ ctx.output_format }}
    </OUTPUT_FORMAT>
  "#
}

// --- Tests ---

test Text2CypherJson1 {
  functions [Text2Cypher]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
    {'nodes': [{'label': 'Forum', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'title', 'type': 'STRING'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'Organisation', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'type', 'type': 'STRING'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}]}, {'label': 'Person', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'firstName', 'type': 'STRING'}, {'name': 'lastName', 'type': 'STRING'}, {'name': 'gender', 'type': 'STRING'}, {'name': 'birthday', 'type': 'DATE'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}, {'name': 'locationIP', 'type': 'STRING'}, {'name': 'browserUsed', 'type': 'STRING'}]}, {'label': 'Tagclass', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}]}, {'label': 'Place', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}, {'name': 'type', 'type': 'STRING'}]}, {'label': 'Tag', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}]}, {'label': 'Comment', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}, {'name': 'locationIP', 'type': 'STRING'}, {'name': 'browserUsed', 'type': 'STRING'}, {'name': 'content', 'type': 'STRING'}, {'name': 'length', 'type': 'INT64'}]}, {'label': 'Post', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'imageFile', 'type': 'STRING'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}, {'name': 'locationIP', 'type': 'STRING'}, {'name': 'browserUsed', 'type': 'STRING'}, {'name': 'language', 'type': 'STRING'}, {'name': 'content', 'type': 'STRING'}, {'name': 'length', 'type': 'INT64'}]}], 'edges': [{'label': 'workAt', 'from': 'Person', 'to': 'Organisation', 'properties': [{'name': 'workFrom', 'type': 'INT64'}]}, {'label': 'forumHasTag', 'from': 'Forum', 'to': 'Tag', 'properties': []}, {'label': 'knows', 'from': 'Person', 'to': 'Person', 'properties': [{'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'hasModerator', 'from': 'Forum', 'to': 'Person', 'properties': []}, {'label': 'likeComment', 'from': 'Person', 'to': 'Comment', 'properties': [{'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'studyAt', 'from': 'Person', 'to': 'Organisation', 'properties': [{'name': 'classYear', 'type': 'INT64'}]}, {'label': 'isPartOf', 'from': 'Place', 'to': 'Place', 'properties': []}, {'label': 'postHasCreator', 'from': 'Post', 'to': 'Person', 'properties': []}, {'label': 'personIsLocatedIn', 'from': 'Person', 'to': 'Place', 'properties': []}, {'label': 'likePost', 'from': 'Person', 'to': 'Post', 'properties': [{'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'postIsLocatedIn', 'from': 'Post', 'to': 'Place', 'properties': []}, {'label': 'containerOf', 'from': 'Forum', 'to': 'Post', 'properties': []}, {'label': 'isSubclassOf', 'from': 'Tagclass', 'to': 'Tagclass', 'properties': []}, {'label': 'organisationIsLocatedIn', 'from': 'Organisation', 'to': 'Place', 'properties': []}, {'label': 'commentIsLocatedIn', 'from': 'Comment', 'to': 'Place', 'properties': []}, {'label': 'postHasTag', 'from': 'Post', 'to': 'Tag', 'properties': []}, {'label': 'commentHasTag', 'from': 'Comment', 'to': 'Tag', 'properties': []}, {'label': 'replyOfComment', 'from': 'Comment', 'to': 'Comment', 'properties': []}, {'label': 'commentHasCreator', 'from': 'Comment', 'to': 'Person', 'properties': []}, {'label': 'hasMember', 'from': 'Forum', 'to': 'Person', 'properties': [{'name': 'joinDate', 'type': 'TIMESTAMP'}]}, {'label': 'replyOfPost', 'from': 'Comment', 'to': 'Post', 'properties': []}, {'label': 'hasType', 'from': 'Tag', 'to': 'Tagclass', 'properties': []}, {'label': 'hasInterest', 'from': 'Person', 'to': 'Tag', 'properties': []}]} 
    "#
  }
}

test Text2CypherXml1 {
  functions [Text2Cypher]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
    <structure>
        <rel label="workAt" from="Person" to="Organisation" />
        <rel label="forumHasTag" from="Forum" to="Tag" />
        <rel label="knows" from="Person" to="Person" />
        <rel label="hasModerator" from="Forum" to="Person" />
        <rel label="likeComment" from="Person" to="Comment" />
        <rel label="studyAt" from="Person" to="Organisation" />
        <rel label="isPartOf" from="Place" to="Place" />
        <rel label="postHasCreator" from="Post" to="Person" />
        <rel label="personIsLocatedIn" from="Person" to="Place" />
        <rel label="likePost" from="Person" to="Post" />
        <rel label="postIsLocatedIn" from="Post" to="Place" />
        <rel label="containerOf" from="Forum" to="Post" />
        <rel label="isSubclassOf" from="Tagclass" to="Tagclass" />
        <rel label="organisationIsLocatedIn" from="Organisation" to="Place" />
        <rel label="commentIsLocatedIn" from="Comment" to="Place" />
        <rel label="postHasTag" from="Post" to="Tag" />
        <rel label="commentHasTag" from="Comment" to="Tag" />
        <rel label="replyOfComment" from="Comment" to="Comment" />
        <rel label="commentHasCreator" from="Comment" to="Person" />
        <rel label="hasMember" from="Forum" to="Person" />
        <rel label="replyOfPost" from="Comment" to="Post" />
        <rel label="hasType" from="Tag" to="Tagclass" />
        <rel label="hasInterest" from="Person" to="Tag" />
    </structure>
    <nodes>
        <node label="Forum">
            <property name="ID" type="INT64" />
            <property name="title" type="STRING" />
            <property name="creationDate" type="TIMESTAMP" />
        </node>
        <node label="Organisation">
            <property name="ID" type="INT64" />
            <property name="type" type="STRING" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
        </node>
        <node label="Person">
            <property name="ID" type="INT64" />
            <property name="firstName" type="STRING" />
            <property name="lastName" type="STRING" />
            <property name="gender" type="STRING" />
            <property name="birthday" type="DATE" />
            <property name="creationDate" type="TIMESTAMP" />
            <property name="locationIP" type="STRING" />
            <property name="browserUsed" type="STRING" />
        </node>
        <node label="Tagclass">
            <property name="ID" type="INT64" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
        </node>
        <node label="Place">
            <property name="ID" type="INT64" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
            <property name="type" type="STRING" />
        </node>
        <node label="Tag">
            <property name="ID" type="INT64" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
        </node>
        <node label="Comment">
            <property name="ID" type="INT64" />
            <property name="creationDate" type="TIMESTAMP" />
            <property name="locationIP" type="STRING" />
            <property name="browserUsed" type="STRING" />
            <property name="content" type="STRING" />
            <property name="length" type="INT64" />
        </node>
        <node label="Post">
            <property name="ID" type="INT64" />
            <property name="imageFile" type="STRING" />
            <property name="creationDate" type="TIMESTAMP" />
            <property name="locationIP" type="STRING" />
            <property name="browserUsed" type="STRING" />
            <property name="language" type="STRING" />
            <property name="content" type="STRING" />
            <property name="length" type="INT64" />
        </node>
    </nodes>
    <relationships>
        <rel label="workAt">
            <property name="workFrom" type="INT64" />
        </rel>
        <rel label="forumHasTag" />
        <rel label="knows">
            <property name="creationDate" type="TIMESTAMP" />
        </rel>
        <rel label="hasModerator" />
        <rel label="likeComment">
            <property name="creationDate" type="TIMESTAMP" />
        </rel>
        <rel label="studyAt">
            <property name="classYear" type="INT64" />
        </rel>
        <rel label="isPartOf" />
        <rel label="postHasCreator" />
        <rel label="personIsLocatedIn" />
        <rel label="likePost">
            <property name="creationDate" type="TIMESTAMP" />
        </rel>
        <rel label="postIsLocatedIn" />
        <rel label="containerOf" />
        <rel label="isSubclassOf" />
        <rel label="organisationIsLocatedIn" />
        <rel label="commentIsLocatedIn" />
        <rel label="postHasTag" />
        <rel label="commentHasTag" />
        <rel label="replyOfComment" />
        <rel label="commentHasCreator" />
        <rel label="hasMember">
            <property name="joinDate" type="TIMESTAMP" />
        </rel>
        <rel label="replyOfPost" />
        <rel label="hasType" />
        <rel label="hasInterest" />
    </relationships>
    "#
  }
}

test Text2CypherYaml1 {
  functions [Text2Cypher]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
structure:
  - label: workAt
    from: Person
    to: Organisation
  - label: forumHasTag
    from: Forum
    to: Tag
  - label: knows
    from: Person
    to: Person
  - label: hasModerator
    from: Forum
    to: Person
  - label: likeComment
    from: Person
    to: Comment
  - label: studyAt
    from: Person
    to: Organisation
  - label: isPartOf
    from: Place
    to: Place
  - label: postHasCreator
    from: Post
    to: Person
  - label: personIsLocatedIn
    from: Person
    to: Place
  - label: likePost
    from: Person
    to: Post
  - label: postIsLocatedIn
    from: Post
    to: Place
  - label: containerOf
    from: Forum
    to: Post
  - label: isSubclassOf
    from: Tagclass
    to: Tagclass
  - label: organisationIsLocatedIn
    from: Organisation
    to: Place
  - label: commentIsLocatedIn
    from: Comment
    to: Place
  - label: postHasTag
    from: Post
    to: Tag
  - label: commentHasTag
    from: Comment
    to: Tag
  - label: replyOfComment
    from: Comment
    to: Comment
  - label: commentHasCreator
    from: Comment
    to: Person
  - label: hasMember
    from: Forum
    to: Person
  - label: replyOfPost
    from: Comment
    to: Post
  - label: hasType
    from: Tag
    to: Tagclass
  - label: hasInterest
    from: Person
    to: Tag
nodes:
  - label: Forum
    properties:
      - name: ID
        type: INT64
      - name: title
        type: STRING
      - name: creationDate
        type: TIMESTAMP
  - label: Organisation
    properties:
      - name: ID
        type: INT64
      - name: type
        type: STRING
      - name: name
        type: STRING
      - name: url
        type: STRING
  - label: Person
    properties:
      - name: ID
        type: INT64
      - name: firstName
        type: STRING
      - name: lastName
        type: STRING
      - name: gender
        type: STRING
      - name: birthday
        type: DATE
      - name: creationDate
        type: TIMESTAMP
      - name: locationIP
        type: STRING
      - name: browserUsed
        type: STRING
  - label: Tagclass
    properties:
      - name: ID
        type: INT64
      - name: name
        type: STRING
      - name: url
        type: STRING
  - label: Place
    properties:
      - name: ID
        type: INT64
      - name: name
        type: STRING
      - name: url
        type: STRING
      - name: type
        type: STRING
  - label: Tag
    properties:
      - name: ID
        type: INT64
      - name: name
        type: STRING
      - name: url
        type: STRING
  - label: Comment
    properties:
      - name: ID
        type: INT64
      - name: creationDate
        type: TIMESTAMP
      - name: locationIP
        type: STRING
      - name: browserUsed
        type: STRING
      - name: content
        type: STRING
      - name: length
        type: INT64
  - label: Post
    properties:
      - name: ID
        type: INT64
      - name: imageFile
        type: STRING
      - name: creationDate
        type: TIMESTAMP
      - name: locationIP
        type: STRING
      - name: browserUsed
        type: STRING
      - name: language
        type: STRING
      - name: content
        type: STRING
      - name: length
        type: INT64
relationships:
  - label: workAt
    properties:
      - name: workFrom
        type: INT64
  - label: forumHasTag
  - label: knows
    properties:
      - name: creationDate
        type: TIMESTAMP
  - label: hasModerator
  - label: likeComment
    properties:
      - name: creationDate
        type: TIMESTAMP
  - label: studyAt
    properties:
      - name: classYear
        type: INT64
  - label: isPartOf
  - label: postHasCreator
  - label: personIsLocatedIn
  - label: likePost
    properties:
      - name: creationDate
        type: TIMESTAMP
  - label: postIsLocatedIn
  - label: containerOf
  - label: isSubclassOf
  - label: organisationIsLocatedIn
  - label: commentIsLocatedIn
  - label: postHasTag
  - label: commentHasTag
  - label: replyOfComment
  - label: commentHasCreator
  - label: hasMember
    properties:
      - name: joinDate
        type: TIMESTAMP
  - label: replyOfPost
  - label: hasType
  - label: hasInterest
    "#
  }
}


test PruneSchemaJson1 {
  functions [PruneSchema]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
    {'nodes': [{'label': 'Forum', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'title', 'type': 'STRING'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'Organisation', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'type', 'type': 'STRING'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}]}, {'label': 'Person', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'firstName', 'type': 'STRING'}, {'name': 'lastName', 'type': 'STRING'}, {'name': 'gender', 'type': 'STRING'}, {'name': 'birthday', 'type': 'DATE'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}, {'name': 'locationIP', 'type': 'STRING'}, {'name': 'browserUsed', 'type': 'STRING'}]}, {'label': 'Tagclass', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}]}, {'label': 'Place', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}, {'name': 'type', 'type': 'STRING'}]}, {'label': 'Tag', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'name', 'type': 'STRING'}, {'name': 'url', 'type': 'STRING'}]}, {'label': 'Comment', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}, {'name': 'locationIP', 'type': 'STRING'}, {'name': 'browserUsed', 'type': 'STRING'}, {'name': 'content', 'type': 'STRING'}, {'name': 'length', 'type': 'INT64'}]}, {'label': 'Post', 'properties': [{'name': 'ID', 'type': 'INT64'}, {'name': 'imageFile', 'type': 'STRING'}, {'name': 'creationDate', 'type': 'TIMESTAMP'}, {'name': 'locationIP', 'type': 'STRING'}, {'name': 'browserUsed', 'type': 'STRING'}, {'name': 'language', 'type': 'STRING'}, {'name': 'content', 'type': 'STRING'}, {'name': 'length', 'type': 'INT64'}]}], 'edges': [{'label': 'workAt', 'from': 'Person', 'to': 'Organisation', 'properties': [{'name': 'workFrom', 'type': 'INT64'}]}, {'label': 'forumHasTag', 'from': 'Forum', 'to': 'Tag', 'properties': []}, {'label': 'knows', 'from': 'Person', 'to': 'Person', 'properties': [{'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'hasModerator', 'from': 'Forum', 'to': 'Person', 'properties': []}, {'label': 'likeComment', 'from': 'Person', 'to': 'Comment', 'properties': [{'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'studyAt', 'from': 'Person', 'to': 'Organisation', 'properties': [{'name': 'classYear', 'type': 'INT64'}]}, {'label': 'isPartOf', 'from': 'Place', 'to': 'Place', 'properties': []}, {'label': 'postHasCreator', 'from': 'Post', 'to': 'Person', 'properties': []}, {'label': 'personIsLocatedIn', 'from': 'Person', 'to': 'Place', 'properties': []}, {'label': 'likePost', 'from': 'Person', 'to': 'Post', 'properties': [{'name': 'creationDate', 'type': 'TIMESTAMP'}]}, {'label': 'postIsLocatedIn', 'from': 'Post', 'to': 'Place', 'properties': []}, {'label': 'containerOf', 'from': 'Forum', 'to': 'Post', 'properties': []}, {'label': 'isSubclassOf', 'from': 'Tagclass', 'to': 'Tagclass', 'properties': []}, {'label': 'organisationIsLocatedIn', 'from': 'Organisation', 'to': 'Place', 'properties': []}, {'label': 'commentIsLocatedIn', 'from': 'Comment', 'to': 'Place', 'properties': []}, {'label': 'postHasTag', 'from': 'Post', 'to': 'Tag', 'properties': []}, {'label': 'commentHasTag', 'from': 'Comment', 'to': 'Tag', 'properties': []}, {'label': 'replyOfComment', 'from': 'Comment', 'to': 'Comment', 'properties': []}, {'label': 'commentHasCreator', 'from': 'Comment', 'to': 'Person', 'properties': []}, {'label': 'hasMember', 'from': 'Forum', 'to': 'Person', 'properties': [{'name': 'joinDate', 'type': 'TIMESTAMP'}]}, {'label': 'replyOfPost', 'from': 'Comment', 'to': 'Post', 'properties': []}, {'label': 'hasType', 'from': 'Tag', 'to': 'Tagclass', 'properties': []}, {'label': 'hasInterest', 'from': 'Person', 'to': 'Tag', 'properties': []}]} 
    "#
  }
}

test PruneSchemaXml1 {
  functions [PruneSchema]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
    <structure>
        <rel label="workAt" from="Person" to="Organisation" />
        <rel label="forumHasTag" from="Forum" to="Tag" />
        <rel label="knows" from="Person" to="Person" />
        <rel label="hasModerator" from="Forum" to="Person" />
        <rel label="likeComment" from="Person" to="Comment" />
        <rel label="studyAt" from="Person" to="Organisation" />
        <rel label="isPartOf" from="Place" to="Place" />
        <rel label="postHasCreator" from="Post" to="Person" />
        <rel label="personIsLocatedIn" from="Person" to="Place" />
        <rel label="likePost" from="Person" to="Post" />
        <rel label="postIsLocatedIn" from="Post" to="Place" />
        <rel label="containerOf" from="Forum" to="Post" />
        <rel label="isSubclassOf" from="Tagclass" to="Tagclass" />
        <rel label="organisationIsLocatedIn" from="Organisation" to="Place" />
        <rel label="commentIsLocatedIn" from="Comment" to="Place" />
        <rel label="postHasTag" from="Post" to="Tag" />
        <rel label="commentHasTag" from="Comment" to="Tag" />
        <rel label="replyOfComment" from="Comment" to="Comment" />
        <rel label="commentHasCreator" from="Comment" to="Person" />
        <rel label="hasMember" from="Forum" to="Person" />
        <rel label="replyOfPost" from="Comment" to="Post" />
        <rel label="hasType" from="Tag" to="Tagclass" />
        <rel label="hasInterest" from="Person" to="Tag" />
    </structure>
    <nodes>
        <node label="Forum">
            <property name="ID" type="INT64" />
            <property name="title" type="STRING" />
            <property name="creationDate" type="TIMESTAMP" />
        </node>
        <node label="Organisation">
            <property name="ID" type="INT64" />
            <property name="type" type="STRING" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
        </node>
        <node label="Person">
            <property name="ID" type="INT64" />
            <property name="firstName" type="STRING" />
            <property name="lastName" type="STRING" />
            <property name="gender" type="STRING" />
            <property name="birthday" type="DATE" />
            <property name="creationDate" type="TIMESTAMP" />
            <property name="locationIP" type="STRING" />
            <property name="browserUsed" type="STRING" />
        </node>
        <node label="Tagclass">
            <property name="ID" type="INT64" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
        </node>
        <node label="Place">
            <property name="ID" type="INT64" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
            <property name="type" type="STRING" />
        </node>
        <node label="Tag">
            <property name="ID" type="INT64" />
            <property name="name" type="STRING" />
            <property name="url" type="STRING" />
        </node>
        <node label="Comment">
            <property name="ID" type="INT64" />
            <property name="creationDate" type="TIMESTAMP" />
            <property name="locationIP" type="STRING" />
            <property name="browserUsed" type="STRING" />
            <property name="content" type="STRING" />
            <property name="length" type="INT64" />
        </node>
        <node label="Post">
            <property name="ID" type="INT64" />
            <property name="imageFile" type="STRING" />
            <property name="creationDate" type="TIMESTAMP" />
            <property name="locationIP" type="STRING" />
            <property name="browserUsed" type="STRING" />
            <property name="language" type="STRING" />
            <property name="content" type="STRING" />
            <property name="length" type="INT64" />
        </node>
    </nodes>
    <relationships>
        <rel label="workAt">
            <property name="workFrom" type="INT64" />
        </rel>
        <rel label="forumHasTag" />
        <rel label="knows">
            <property name="creationDate" type="TIMESTAMP" />
        </rel>
        <rel label="hasModerator" />
        <rel label="likeComment">
            <property name="creationDate" type="TIMESTAMP" />
        </rel>
        <rel label="studyAt">
            <property name="classYear" type="INT64" />
        </rel>
        <rel label="isPartOf" />
        <rel label="postHasCreator" />
        <rel label="personIsLocatedIn" />
        <rel label="likePost">
            <property name="creationDate" type="TIMESTAMP" />
        </rel>
        <rel label="postIsLocatedIn" />
        <rel label="containerOf" />
        <rel label="isSubclassOf" />
        <rel label="organisationIsLocatedIn" />
        <rel label="commentIsLocatedIn" />
        <rel label="postHasTag" />
        <rel label="commentHasTag" />
        <rel label="replyOfComment" />
        <rel label="commentHasCreator" />
        <rel label="hasMember">
            <property name="joinDate" type="TIMESTAMP" />
        </rel>
        <rel label="replyOfPost" />
        <rel label="hasType" />
        <rel label="hasInterest" />
    </relationships>
    "#
  }
}

test PruneSchemaYaml1 {
  functions [PruneSchema]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
structure:
  - label: workAt
    from: Person
    to: Organisation
  - label: forumHasTag
    from: Forum
    to: Tag
  - label: knows
    from: Person
    to: Person
  - label: hasModerator
    from: Forum
    to: Person
  - label: likeComment
    from: Person
    to: Comment
  - label: studyAt
    from: Person
    to: Organisation
  - label: isPartOf
    from: Place
    to: Place
  - label: postHasCreator
    from: Post
    to: Person
  - label: personIsLocatedIn
    from: Person
    to: Place
  - label: likePost
    from: Person
    to: Post
  - label: postIsLocatedIn
    from: Post
    to: Place
  - label: containerOf
    from: Forum
    to: Post
  - label: isSubclassOf
    from: Tagclass
    to: Tagclass
  - label: organisationIsLocatedIn
    from: Organisation
    to: Place
  - label: commentIsLocatedIn
    from: Comment
    to: Place
  - label: postHasTag
    from: Post
    to: Tag
  - label: commentHasTag
    from: Comment
    to: Tag
  - label: replyOfComment
    from: Comment
    to: Comment
  - label: commentHasCreator
    from: Comment
    to: Person
  - label: hasMember
    from: Forum
    to: Person
  - label: replyOfPost
    from: Comment
    to: Post
  - label: hasType
    from: Tag
    to: Tagclass
  - label: hasInterest
    from: Person
    to: Tag
nodes:
  - label: Forum
    properties:
      - name: ID
        type: INT64
      - name: title
        type: STRING
      - name: creationDate
        type: TIMESTAMP
  - label: Organisation
    properties:
      - name: ID
        type: INT64
      - name: type
        type: STRING
      - name: name
        type: STRING
      - name: url
        type: STRING
  - label: Person
    properties:
      - name: ID
        type: INT64
      - name: firstName
        type: STRING
      - name: lastName
        type: STRING
      - name: gender
        type: STRING
      - name: birthday
        type: DATE
      - name: creationDate
        type: TIMESTAMP
      - name: locationIP
        type: STRING
      - name: browserUsed
        type: STRING
  - label: Tagclass
    properties:
      - name: ID
        type: INT64
      - name: name
        type: STRING
      - name: url
        type: STRING
  - label: Place
    properties:
      - name: ID
        type: INT64
      - name: name
        type: STRING
      - name: url
        type: STRING
      - name: type
        type: STRING
  - label: Tag
    properties:
      - name: ID
        type: INT64
      - name: name
        type: STRING
      - name: url
        type: STRING
  - label: Comment
    properties:
      - name: ID
        type: INT64
      - name: creationDate
        type: TIMESTAMP
      - name: locationIP
        type: STRING
      - name: browserUsed
        type: STRING
      - name: content
        type: STRING
      - name: length
        type: INT64
  - label: Post
    properties:
      - name: ID
        type: INT64
      - name: imageFile
        type: STRING
      - name: creationDate
        type: TIMESTAMP
      - name: locationIP
        type: STRING
      - name: browserUsed
        type: STRING
      - name: language
        type: STRING
      - name: content
        type: STRING
      - name: length
        type: INT64
relationships:
  - label: workAt
    properties:
      - name: workFrom
        type: INT64
  - label: forumHasTag
  - label: knows
    properties:
      - name: creationDate
        type: TIMESTAMP
  - label: hasModerator
  - label: likeComment
    properties:
      - name: creationDate
        type: TIMESTAMP
  - label: studyAt
    properties:
      - name: classYear
        type: INT64
  - label: isPartOf
  - label: postHasCreator
  - label: personIsLocatedIn
  - label: likePost
    properties:
      - name: creationDate
        type: TIMESTAMP
  - label: postIsLocatedIn
  - label: containerOf
  - label: isSubclassOf
  - label: organisationIsLocatedIn
  - label: commentIsLocatedIn
  - label: postHasTag
  - label: commentHasTag
  - label: replyOfComment
  - label: commentHasCreator
  - label: hasMember
    properties:
      - name: joinDate
        type: TIMESTAMP
  - label: replyOfPost
  - label: hasType
  - label: hasInterest
    "#
  }
}

test Text2CypherCompressed1 {
  functions [Text2CypherCompressed]
  args {
    question "What are the first/last names of people who live in 'Glasgow', and are interested in the tag 'Napoleon'?"
    compressed_schema #"
    ## [COMPRESSED_SCHEMA]

    3-[1]->2 : {1,3,7,8,9,10,11,12} -[17]-> {1,4,5,6}
    1-[2]->6 : {1,2,3} -[]-> {1,5,6}
    3-[3]->3 : {1,3,7,8,9,10,11,12} -[3]-> {1,3,7,8,9,10,11,12}
    1-[4]->3 : {1,2,3} -[]-> {1,3,7,8,9,10,11,12}
    3-[5]->7 : {1,3,7,8,9,10,11,12} -[3]-> {1,3,11,12,13,14}
    3-[6]->2 : {1,3,7,8,9,10,11,12} -[18]-> {1,4,5,6}
    5-[7]->5 : {1,4,5,6} -[]-> {1,4,5,6}
    8-[8]->3 : {1,3,11,12,13,14,15,16} -[]-> {1,3,7,8,9,10,11,12}
    3-[9]->5 : {1,3,7,8,9,10,11,12} -[]-> {1,4,5,6}
    3-[10]->8 : {1,3,7,8,9,10,11,12} -[3]-> {1,3,11,12,13,14,15,16}
    8-[11]->5 : {1,3,11,12,13,14,15,16} -[]-> {1,4,5,6}
    1-[12]->8 : {1,2,3} -[]-> {1,3,11,12,13,14,15,16}
    4-[13]->4 : {1,5,6} -[]-> {1,5,6}
    2-[14]->5 : {1,4,5,6} -[]-> {1,4,5,6}
    7-[15]->5 : {1,3,11,12,13,14} -[]-> {1,4,5,6}
    8-[16]->6 : {1,3,11,12,13,14,15,16} -[]-> {1,5,6}
    7-[17]->6 : {1,3,11,12,13,14} -[]-> {1,5,6}
    7-[18]->7 : {1,3,11,12,13,14} -[]-> {1,3,11,12,13,14}
    7-[19]->3 : {1,3,11,12,13,14} -[]-> {1,3,7,8,9,10,11,12}
    1-[20]->3 : {1,2,3} -[19]-> {1,3,7,8,9,10,11,12}
    7-[21]->8 : {1,3,11,12,13,14} -[]-> {1,3,11,12,13,14,15,16}
    6-[22]->4 : {1,5,6} -[]-> {1,5,6}
    3-[23]->6 : {1,3,7,8,9,10,11,12} -[]-> {1,5,6}

    ## [NODES]
    ```
    1 = Forum
    2 = Organisation
    3 = Person
    4 = Tagclass
    5 = Place
    6 = Tag
    7 = Comment
    8 = Post
    ```

    ## [RELATIONSHIPS]
    ```
    1 = workAt
    2 = forumHasTag
    3 = knows
    4 = hasModerator
    5 = likeComment
    6 = studyAt
    7 = isPartOf
    8 = postHasCreator
    9 = personIsLocatedIn
    10 = likePost
    11 = postIsLocatedIn
    12 = containerOf
    13 = isSubclassOf
    14 = organisationIsLocatedIn
    15 = commentIsLocatedIn
    16 = postHasTag
    17 = commentHasTag
    18 = replyOfComment
    19 = commentHasCreator
    20 = hasMember
    21 = replyOfPost
    22 = hasType
    23 = hasInterest
    ```

    ## [PROPERTIES]
    ```
    1 = ID
    2 = title
    3 = creationDate
    4 = type
    5 = name
    6 = url
    7 = firstName
    8 = lastName
    9 = gender
    10 = birthday
    11 = locationIP
    12 = browserUsed
    13 = content
    14 = length
    15 = imageFile
    16 = language
    17 = workFrom
    18 = classYear
    19 = joinDate
    ```


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
    "#
  }
}

test AnswerQuestionBinary1 {
  functions [AnswerQuestionBinary]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    context "['hasWrittenPostWithSafari', 'False']"
  }
}

test AnswerQuestionBinary2 {
  functions [AnswerQuestionBinary]
  args {
    question "Is there a person with the last name 'Gurung' who's a moderator of a forum with the tag 'Norah_Jones'?"
    context "['p.lastName', 'Gurung']"
  }
}

test PruneSchemaDDL1 {
  functions [PruneSchemaDDL]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
    CREATE NODE TABLE Comment(ID INT64, creationDate TIMESTAMP, locationIP STRING, browserUsed STRING, content STRING, length INT64, PRIMARY KEY(ID));
    CREATE NODE TABLE Forum(ID INT64, title STRING, creationDate TIMESTAMP, PRIMARY KEY(ID));
    CREATE NODE TABLE Organisation(ID INT64, type STRING, name STRING, url STRING, PRIMARY KEY(ID));
    CREATE NODE TABLE Person(ID INT64, firstName STRING, lastName STRING, gender STRING, birthday DATE, creationDate TIMESTAMP, locationIP STRING, browserUsed STRING, PRIMARY KEY(ID));
    CREATE NODE TABLE Place(ID INT64, name STRING, url STRING, type STRING, PRIMARY KEY(ID));
    CREATE NODE TABLE Post(ID INT64, imageFile STRING, creationDate TIMESTAMP, locationIP STRING, browserUsed STRING, language STRING, content STRING, length INT64, PRIMARY KEY(ID));
    CREATE NODE TABLE Tag(ID INT64, name STRING, url STRING, PRIMARY KEY(ID));
    CREATE NODE TABLE Tagclass(ID INT64, name STRING, url STRING, PRIMARY KEY(ID));
    CREATE REL TABLE containerOf(FROM Forum TO Post);
    CREATE REL TABLE commentHasCreator(FROM Comment TO Person);
    CREATE REL TABLE postHasCreator(FROM Post TO Person);
    CREATE REL TABLE hasInterest(FROM Person TO Tag);
    CREATE REL TABLE hasMember(FROM Forum TO Person, joinDate TIMESTAMP);
    CREATE REL TABLE hasModerator(FROM Forum TO Person);
    CREATE REL TABLE commentHasTag(FROM Comment TO Tag);
    CREATE REL TABLE forumHasTag(FROM Forum TO Tag);
    CREATE REL TABLE postHasTag(FROM Post TO Tag);
    CREATE REL TABLE hasType(FROM Tag TO Tagclass);
    CREATE REL TABLE commentIsLocatedIn(FROM Comment TO Place);
    CREATE REL TABLE organisationIsLocatedIn(FROM Organisation TO Place);
    CREATE REL TABLE personIsLocatedIn(FROM Person TO Place);
    CREATE REL TABLE postIsLocatedIn(FROM Post TO Place);
    CREATE REL TABLE isPartOf(FROM Place TO Place);
    CREATE REL TABLE isSubclassOf(FROM Tagclass TO Tagclass);
    CREATE REL TABLE knows(FROM Person TO Person, creationDate TIMESTAMP);
    CREATE REL TABLE likeComment(FROM Person TO Comment, creationDate TIMESTAMP);
    CREATE REL TABLE likePost(FROM Person TO Post, creationDate TIMESTAMP);
    CREATE REL TABLE replyOfComment(FROM Comment TO Comment);
    CREATE REL TABLE replyOfPost(FROM Comment TO Post);
    CREATE REL TABLE studyAt(FROM Person TO Organisation, classYear INT64);
    CREATE REL TABLE workAt(FROM Person TO Organisation, workFrom INT64);
    "#
  }
}

test Text2CypherDDLSchema1 {
  functions [Text2Cypher]
  args {
    question "Has the person 'Justine Fenter' written a post using the 'Safari' browser?"
    schema #"
    CREATE NODE TABLE Person(ID INT64, firstName STRING, lastName STRING, browserUsed STRING, PRIMARY KEY(ID));
    CREATE NODE TABLE Post(ID INT64, browserUsed STRING, PRIMARY KEY(ID));
    CREATE REL TABLE postHasCreator(FROM Post TO Person);
    "#
  }
}