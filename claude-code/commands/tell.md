---
description: Read your last response aloud through TellCode
allowed-tools: Bash(/home/olek/.tellcode/tell.sh:*)
---

Send your previous response to TellCode so the user can listen to it on their phone.

## Step 1: rewrite for speech

Take your last message (the response you gave right before this command) and rewrite it as if you were reading it aloud to a human over the phone. Do not answer it, extend it, or add information you don't have. Just rewrite.

- If the message asked the user a question, lead with the question so they hear it first, and keep it phrased as a question.
- Drop markdown formatting: headers, bold, italics, backticks, bullet markers, tables.
- Don't read technical artifacts literally (code blocks, JSON, file paths, URLs, shell commands, stack traces, diffs). Briefly describe what they are instead: "a shell command that installs the dependencies", "a JSON object with the key set to the value".
- Never spell out URLs. Refer to them by host or purpose: "a link to GitHub", "the localhost URL on port 8080".
- When a file name must be spoken, transcribe punctuation into words: AGENTS.md becomes "agents dot em dee".
- Keep the meaning and key facts intact. Use natural spoken English. Be concise: skip filler, redundant detail, and repetitive structure.

## Step 2: title

Write a title of about three words that says what the message is about. Examples: "Tests passing now", "Need your decision", "Migration finished". Plain words only — no quotes or apostrophes.

## Step 3: send

Run the TellCode sender script exactly once. The title is the argument; the spoken text goes in on stdin, so no JSON and no escaping is needed — write the text as it should be read.

```bash
/home/olek/.tellcode/tell.sh '<title>' <<'TEXT'
<spoken text>
TEXT
```

Do not print the rewritten text. On success the script prints `Sent to TellCode: <title>` — reply with that single line. If it fails, report the error it printed in one line.
