---
name: detrope
description: Reviews text for AI writing tropes and fixes them. Use when you want to clean up AI-generated writing for clarity and readability.
---

## Word Choice
- Remove "quietly", "deeply", "fundamentally", "remarkably", "arguably" when used to inject false significance
- Remove "delve", "certainly", "utilize", "leverage" (as verb), "robust", "streamline", "harness"
- Replace "tapestry", "landscape", "paradigm", "synergy", "ecosystem" with simpler words
- Replace "serves as", "stands as", "marks", "represents" with "is"/"are" when appropriate

## Sentence Structure
- Kill "It's not X -- it's Y" negative parallelism (the single worst AI tell)
- Kill "Not X. Not Y. Just Z." dramatic countdown
- Kill "The X? A Y." self-posed rhetorical questions
- Kill anaphora abuse (same sentence opening repeated 3+ times)
- Kill tricolon abuse (rule-of-three used repeatedly)
- Remove filler transitions: "It's worth noting", "It bears mentioning", "Importantly", "Interestingly", "Notably"
- Remove shallow "-ing" phrase analysis tacked onto sentences ("highlighting its importance", "reflecting broader trends", "contributing to the development of")
- Fix false ranges ("from X to Y" where X and Y aren't on a real scale)
- Remove gerund fragment litanies (streams of verbless fragments used as illustration)

## Paragraph Structure
- Fix excessive short punchy fragments used as standalone paragraphs
- Fix listicles disguised as prose ("The first... The second... The third...")

## Tone
- Remove false suspense: "Here's the kicker", "Here's the thing", "Here's where it gets interesting"
- Remove patronizing analogies: "Think of it as...", "Think of it like..."
- Remove "Imagine a world where..."
- Remove false vulnerability and performative self-awareness
- Remove "The truth is simple" / "The reality is" assertions that substitute for proof
- Deflate grandiose stakes inflation -- not everything reshapes civilization
- Remove pedagogical hand-holding: "Let's break this down", "Let's unpack this", "Let's explore"
- Replace vague attributions ("experts argue", "industry reports suggest") with specifics or remove
- Remove invented compound labels ("supervision paradox", "acceleration trap") unless actually defined

## Formatting
- Reduce em dash overuse (2-3 per piece max, not 20)
- Remove bold-first bullet pattern (not every list item needs a bolded keyword)
- Replace unicode arrows and smart quotes with plain ASCII

## Composition
- Remove fractal summaries (don't re-summarize what was just said)
- Flag dead metaphors beaten into the ground
- Flag historical analogy stacking (rapid-fire company/revolution lists)
- Flag one-point dilution (same argument restated many ways)
- Remove signposted conclusions ("In conclusion", "To sum up", "In summary")
- Remove "Despite its challenges..." dismiss-and-pivot pattern

## Rules
- Any single trope used once can be fine. Flag when multiple tropes cluster or one repeats.
- Write like a human: varied, imperfect, specific.
- Preserve the author's actual meaning and argument. Only fix the AI-sounding patterns, don't rewrite substance.
- Output the cleaned text first, then a short changelog.
