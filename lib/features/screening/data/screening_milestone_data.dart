class MilestoneItem {
  final String domain;
  final String expectedMilestone;
  final String example;
  final String recommendation;

  const MilestoneItem({
    required this.domain,
    required this.expectedMilestone,
    required this.example,
    required this.recommendation,
  });
}

class ScreeningMilestoneData {
  /// Real-world examples for question items
  static const Map<String, String> itemExamples = {
    // Parent 5-11 items
    'p5_1': 'Child often asks "What?", "Huh?", or waits to see what other children do before following instructions.',
    'p5_2': 'For example: "Wash your hands, take your plate, and sit at the table." Child only washes hands and forgets the rest.',
    'p5_3': 'Child pauses for long moments, clicks fingers, or substitutes "the thingy" / "that stuff" when trying to name familiar objects.',
    'p5_4': 'Child says "I lost my red dinosaur with sharp claws" instead of just "where is that toy thing".',
    'p5_5': 'Child says "Him going outside" or "Cat jump table" dropping small grammatical words like "is", "a", or "the".',
    'p5_6': 'Child uses complete sentences ("Can we go to the park because it stopped raining?") rather than short fragments.',
    'p5_7': 'When recounting a movie or story, events are mixed up or characters appear without introduction ("He got hit then he ran and then the boy came").',
    'p5_8': 'Child can smoothly tell you about lunchtime: "First we played tag, then Sara shared her cookies with me."',
    'p5_9': 'During a chat about dinner, child suddenly talks about an unrelated cartoon character without transitioning.',
    'p5_10': 'Child naturally waits for you to finish speaking and responds to your question instead of talking over you.',
    'p5_11': 'Child does not turn when their name is called in a quiet room, or turns the TV volume noticeably high.',
    'p5_12': 'Grandparents or unfamiliar visitors frequently ask you: "What did they just say?"',
    'p5_13': 'Child says "I runned fast" or "We goed to grandma" well past the age when past tense irregulars are usually learned.',
    'p5_14': 'Starts telling what happened at school, wanders into three unrelated stories, and forgets how the original story ended.',
    'p5_15': 'Child takes phrases literally (e.g., when you say "hold your horses", they look around for actual horses).',
    'p5_16': 'Child clenches fists, cries, or gives up easily when trying to explain an idea they cannot find words for.',
    'p5_17': 'Child comfortably switches words or knows vocabulary in home language and English without distress.',
    'p5_18': 'Child misses when a peer is being playful vs upset, or does not notice subtle facial expressions.',
    'p5_19': 'Child naturally links ideas: "We had indoor recess because the playground was too muddy."',
    'p5_20': 'A noticeable drop where words or sentence patterns the child previously used have suddenly vanished.',

    // Parent 11-18 items
    'p11_1': 'Struggles with homework instructions like "Analyze chapter 3, underline three metaphors, and summarize in your notebook."',
    'p11_2': 'Difficulty understanding sarcastic jokes, peer banter, or idiomatic phrases like "piece of cake" or "bite the bullet".',
    'p11_3': 'Frequently says "You know, the thing... on the counter... the machine that makes it hot" instead of "toaster".',
    'p11_4': 'Uses varied descriptive vocabulary (e.g. "reluctant", "gigantic", "exhausted") rather than repetitive basic words.',
    'p11_5': 'Struggles to organize long essay paragraphs or complex multi-clause sentences in conversation.',
  };

  /// Domain specific clinical milestones and guidance
  static const Map<String, MilestoneItem> domainMilestones5to11 = {
    'understanding': MilestoneItem(
      domain: 'Understanding Language (Receptive)',
      expectedMilestone: 'Follows 3-step instructions, understands temporal concepts (before, after, while), and grasps indirect requests.',
      example: 'Should follow: "Before you put your shoes on, put your homework in your bag."',
      recommendation: 'Break complex directions into numbered 1-step chunks. Give 5–10 seconds of processing time before repeating.',
    ),
    'words': MilestoneItem(
      domain: 'Words & Vocabulary (Semantics)',
      expectedMilestone: 'Expresses specific categories, antonyms/synonyms, and defines words using function, appearance, and category.',
      example: 'Defines an apple as: "A round red fruit you eat that grows on trees."',
      recommendation: 'Use semantic mapping: when learning a new word, explore what it looks like, where it belongs, and what it does.',
    ),
    'grammar': MilestoneItem(
      domain: 'Grammar & Sentences (Syntax & Morphology)',
      expectedMilestone: 'Uses complex sentences with conjunctions (because, so, although), accurate verb tenses, and correct pronouns.',
      example: 'Uses: "She told him that they would go if the weather was nice."',
      recommendation: 'Practice "recasting": repeat the child\'s sentence correctly without saying "no, that is wrong" (e.g. child: "Him ran", adult: "Yes, he ran so fast!").',
    ),
    'stories': MilestoneItem(
      domain: 'Stories & Explanations (Narrative)',
      expectedMilestone: 'Retells personal events and stories with beginning, problem, sequence of events, and logical resolution.',
      example: 'Includes setting, characters, problem, feelings, and how the problem was solved.',
      recommendation: 'Use visual story cue cards (Who? Where? What problem? How did it end?) to structure bedtime or school stories.',
    ),
    'conversation': MilestoneItem(
      domain: 'Conversation & Social Use (Pragmatics)',
      expectedMilestone: 'Maintains topic across multiple conversational turns, repairs misunderstandings, and adjusts language for the listener.',
      example: 'Explains things in more detail to a toddler than to an adult.',
      recommendation: 'Role-play conversational scenarios and explicitly teach conversational repair phrases ("What do you mean by that?").',
    ),
  };

  /// Adolescent milestones (11–18 years)
  static const Map<String, MilestoneItem> domainMilestones11to18 = {
    'understanding': MilestoneItem(
      domain: 'Higher-Level Comprehension',
      expectedMilestone: 'Understands sarcasm, irony, abstract figurative idioms, and multi-paragraph academic lectures.',
      example: 'Recognizes tone changes that signify sarcasm or playful irony among friends.',
      recommendation: 'Pre-teach academic vocabulary and provide written or visual organizers alongside spoken lectures.',
    ),
    'words': MilestoneItem(
      domain: 'Academic Lexicon & Word Retrieval',
      expectedMilestone: 'Rapid retrieval of specialized curriculum terms (scientific, literary, mathematical) without word-finding blocks.',
      example: 'Can explain concepts without excessive circumlocution or hesitation.',
      recommendation: 'Encourage mind-mapping and personal vocabulary glossaries with visual anchors.',
    ),
    'grammar': MilestoneItem(
      domain: 'Complex Syntactic Form',
      expectedMilestone: 'Produces complex sentence structures with embedded relative clauses and cohesive conjunctive adverbs.',
      example: 'Writes: "Although the experiment yielded unexpected outcomes, the methodology remained sound."',
      recommendation: 'Sentence-combining exercises: combine 2–3 short sentences into one rich, coherent sentence.',
    ),
    'stories': MilestoneItem(
      domain: 'Expository & Persuasive Discourse',
      expectedMilestone: 'Constructs multi-perspective arguments, compares opposing viewpoints, and summarizes non-fiction texts.',
      example: 'Logically justifies why one policy is more equitable than another.',
      recommendation: 'Use graphic organizers like Venn diagrams and claim-evidence-reasoning outlines.',
    ),
    'conversation': MilestoneItem(
      domain: 'Peer Social Pragmatics',
      expectedMilestone: 'Navigates complex peer group dynamics, codeswitches between formal and informal contexts, and reads non-verbal cues.',
      example: 'Speaks differently to a teacher in class versus peers in the hallway.',
      recommendation: 'Discuss real-world conversational scenarios and communication intent in safe, supportive discussions.',
    ),
  };

  /// Get benchmark for domain and age band
  static MilestoneItem getMilestone(String domainId, String ageBand) {
    if (ageBand == '11_18') {
      return domainMilestones11to18[domainId] ??
          MilestoneItem(
            domain: domainId,
            expectedMilestone: 'Age-appropriate communication milestone.',
            example: 'Typical daily language use.',
            recommendation: 'Support with visual aids and patient listening.',
          );
    }
    return domainMilestones5to11[domainId] ??
        MilestoneItem(
          domain: domainId,
          expectedMilestone: 'Age-appropriate communication milestone.',
          example: 'Typical daily language use.',
          recommendation: 'Support with conversational modeling and interactive reading.',
        );
  }
}
