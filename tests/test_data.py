# Suite 1a: Exact match queries

suite_1a = [
    {
        "question": 'What are the first/last  names of people who live in "Glasgow", and are interested in the tag "Napoleon"?',
        "expected_values": ["Thomas", "Brown"],
    },
    {
        "question": 'Show me the IDs of all posts by "Lei Zhang" whose content has the term "Zulu".',
        "expected_values": [2061586474857, 2061586474860],
    },
    {
        "question": "What is the first/last name of the person who created post ID 962077547172, and where did they study?",
        "expected_values": ["Mads", "Haugland", "Norwegian_School_of_Sport_Sciences"],
    },
    {
        "question": "Give me the IDs of comments created by 'Alfredo Gomez' with a size greater than 100",
        "expected_values": [1924145496676],
    },
    {
        "question": 'What are the first names of persons with the last name "Choi" who are members of forums whose title contains "John Brown"?',
        "expected_values": ["Akihiko"],
    },
    {
        "question": 'List the IDs of employees who work at "Nova_Air" and whose last name is "Bravo".',
        "expected_values": [
            15393162799645,
            28587302332692,
            17592186046501,
            19791209310595,
            15393162791641,
        ],
    },
    {
        "question": "What are the names of places from where the person ID 17592186048023 made comments that replied to posts tagged with 'Jamaica'?",
        "expected_values": ["India"],
    },
    {
        "question": 'What are the distinct IDs of persons born after 1 January 1990 who are moderators of Forums containing the term "Emilio Fernandez"?',
        "expected_values": [13194139534410],
    },
    {
        "question": "What's the ID and first name of the person of last name 'Johansson' who knows a person that studied at a university located in 'Tallinn'?",
        "expected_values": ["Hans"],
    },
    {
        "question": 'What are the unique IDs of persons who commented on posts that have the tag "Cate_Blanchett"?',
        "expected_values": [24189255819727, 8796093029267],
    },
]


# Suite 1b: Counting/aggregation queries

suite_1b = [
    {
        "question": 'Which organization NOT of the type "university" has the most employees, and how many employees do they have?',
        "expected_values": ["MDLR_Airlines", 190],
    },
    {
        "question": 'Count the total number of comments (whose content is not null) created by people living in "Berlin".',
        "expected_values": [3229],
    },
    {
        "question": 'What is the total number of persons who liked comments created by "Rafael Alonso"?',
        "expected_values": [2293],
    },
    {
        "question": 'How many forums are there with tags belonging to the "Athlete" tagclass?',
        "expected_values": [37],
    },
    {
        "question": 'What is the total number of forums moderated by employees of "Air_Tanzania"?.',
        "expected_values": [278],
    },
    {
        "question": 'How many posts with content containing the term "Copernicus" were created by persons located in Mumbai?',
        "expected_values": [3],
    },
    {
        "question": 'For people who studied at "Indian_Institute_of_Science", what tag are they most interested in?',
        "expected_values": ["Hamid_Karzai"],
    },
    {
        "question": 'How many people studying at "The_Oxford_Educational_Institutions" have an interest in the tag "William_Shakespeare"?',
        "expected_values": [20],
    },
    {
        "question": "What's the name of the place with the most comments whose tag contains the term 'Copernicus', and how many comments are there?",
        "expected_values": ["India", 242],
    },
    {
        "question": 'How many comments whose contents contain the term "World War II" are larger than 1000 characters in size?',
        "expected_values": [3],
    },
]

# Suite 1c: Binary answer (Yes/No) queries

suite_1c = [
    {
        "question": 'Has the person named "Bill Moore" liked the post with ID 1649268446863?',
        "expected_values": ["Yes"],
    },
    {
        "question": 'Did anyone who works at "Linxair" create a comment that replied to a post?',
        "expected_values": ["Yes"],
    },
    {
        "question": "Is there a person with the last name 'Gurung' who's a moderator of a forum with the tag 'Norah_Jones'?",
        "expected_values": ["Yes"],
    },
    {
        "question": 'Is there a person who lives in "Paris" and has an interest in the "Cate_Blanchett"?',
        "expected_values": ["No"],
    },
    {
        "question": "Are there any comments created by a person that reply to a post also created by the same person?",
        "expected_values": ["Yes"],
    },
    {
        "question": 'Does "Amit Singh" know anyone who has studied at "MIT_School_of_Engineering"?',
        "expected_values": ["No"],
    },
    {
        "question": "Are there any forums with the tag that person ID 10995116287854 is a member of?",
        "expected_values": ["Yes"],
    },
    {
        "question": 'Did any person from Toronto create a comment with the tag "Winston_Churchill"?',
        "expected_values": ["Yes"],
    },
    {
        "question": 'Is it true that there are people located in Manila who are interested in a tag that belongs to the type "BritishRoyalty"?',
        "expected_values": ["Yes"],
    },
    {
        "question": 'Has the person "Justine Fenter" written a post using the "Safari" browser?',
        "expected_values": ["No"],
    },
]
