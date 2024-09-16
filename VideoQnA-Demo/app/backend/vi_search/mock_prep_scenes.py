import uuid

def generate_uuid():
    return str(uuid.uuid4())

mock_video1_sections = [
    "Section 1: Pandas primarily feed on bamboo, which makes up 99% of their diet, despite being carnivores by classification.",
    "Section 2: Pandas have a unique thumb-like wrist bone that helps them grip and strip bamboo efficiently.",
    "Section 3: In addition to bamboo, pandas occasionally eat other vegetation and small animals, especially when bamboo is scarce."
]

mock_video2_sections = [
    "Section 1: Zebras rely on their speed and agility to escape predators like lions, hyenas, and cheetahs in the African savannah.",
    "Section 2: Zebras use their distinctive stripes to confuse predators, especially when moving in groups, creating a visual blur.",
    "Section 3: Despite their defense mechanisms, zebras are vulnerable to attacks when drinking water or when separated from their herd."
]

mock_video3_sections = [
    "Section 1: Snow birds, like geese and swans, migrate annually to warmer climates during winter months to escape harsh cold environments.",
    "Section 2: These birds use established migratory routes and natural landmarks, often traveling thousands of miles to reach their destinations.",
    "Section 3: Climate change and habitat loss are increasingly affecting snow bird migration patterns, leading to shifts in timing and routes."
]

mock_videos = {
    "video1": mock_video1_sections,
    "video2": mock_video2_sections,
    "video3": mock_video3_sections
}

mock_start_end_pairs = [
    ("00:00:00", "00:00:30"),
    ("00:00:30", "00:01:00"),
    ("00:01:00", "00:01:30")
]

def mock_prompt_content_generator():
    ''' Returns a generator of video sections. '''
    video_id = 0
    for video_name, sections in mock_videos.items():
        video_id += 1
        for section_index, section in enumerate(sections):
            start_end = mock_start_end_pairs[min(section_index, len(mock_start_end_pairs) - 1)]
            yield video_id, video_name, '', section_index, {"start": start_end[0], "end": start_end[1], "content": section}


def mock_sections_generator(embedding_cb, embeddings_col_name="content_vector"):
    ''' Returns a generator of sections. '''

    for video_id, video_name, partition, section_index, section in mock_prompt_content_generator():
        content = section['content']

        proc_section = {
            "id": generate_uuid(),

            "section_idx": section_index,
            "start_time": section['start'],
            "end_time": section['end'],
            # "scene_idx": section['id'],  # Not sure what this field holds
            "content": content,
            # "account_id": account_details['account_id'],
            # "location": account_details["location"],
            "video_id": video_id,
            "partition": '',
            "video_name": video_name
            }

        if embedding_cb is not None:
            proc_section.update({embeddings_col_name: embedding_cb(content)})

        yield proc_section
