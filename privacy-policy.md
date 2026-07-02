# Privacy Policy for Julyeo (줄여줘)

**Last updated: July 2, 2026**

## Overview

Julyeo ("줄여줘") is a summarization app that uses on-device AI to process audio recordings, photos, and audio files. We are committed to protecting your privacy.

**Julyeo does not collect, store, or transmit any personal data to external servers.**

---

## Data We Access

### Microphone
- Used to record audio for transcription and summarization.
- Audio is transcribed using Apple's Speech Recognition framework. Depending on your device and language settings, Apple may process this speech recognition on-device or via Apple's servers (per [Apple's Privacy Policy](https://www.apple.com/legal/privacy/)) — Julyeo does not control this and does not operate its own speech-recognition servers.
- Julyeo itself never uploads your recordings to Julyeo's or any third party's servers.

### Camera & Photos
- Used to capture or select images for text extraction (OCR).
- Images are processed entirely on your device using Apple's Vision framework.
- Photos are never uploaded to any server.

### Audio Files
- You may import audio files (m4a, mp3, wav) for transcription.
- Files are processed entirely on your device.
- Files are never uploaded to any server.

---

## On-Device Processing

Text extraction and summarization are performed **locally on your device**:

- **Apple Vision** (VNRecognizeTextRequest) — on-device OCR for photos and documents.
- **Apple Intelligence / Foundation Models** (on-device LLM) — on-device summarization.

Speech-to-text uses **Apple Speech Recognition** (SFSpeechRecognizer), which may run on-device or through Apple's servers depending on your device and language (see above).

Julyeo does not send your recordings, photos, or extracted text to Julyeo's own servers, to Anthropic, or to any advertising or analytics third party.

---

## Data Storage

Summaries you choose to save are stored **locally on your device** using SwiftData. This data never leaves your device unless you explicitly share it using the system share sheet.

---

## Third-Party Services

Julyeo does not integrate any third-party analytics, advertising, or tracking SDKs.

---

## Children's Privacy

Julyeo does not knowingly collect any information from children under 13.

---

## Changes to This Policy

We may update this policy from time to time. Changes will be reflected by the "Last updated" date above.

---

## Contact

If you have any questions about this Privacy Policy, please contact us:

**GitHub:** [https://github.com/HwangWoonChun/Julyeo](https://github.com/HwangWoonChun/Julyeo)
