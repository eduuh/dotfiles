---
description: Record voice and transcribe to text
allowed-tools: Bash, Read
---

I want to give you voice input. Run my voice recording script and use the transcription as my request.

```bash
~/.bin/voice 2>&1
```

The transcription will be printed between the `---` markers in the output. Treat that text as my request and respond to it.
