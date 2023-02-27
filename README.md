# firefox-emoji-barcode
Daily Firefox Emoji barcode from support.mozilla.org (SUMO) Firefox Desktop support questions

## Linux, Mac and Windows emojis

* Question mark is for when we can't determine the operating system
```bash
cd EMOJI_PNG
../createEmojiPNG.rb '🪟' 'a50026'
../createEmojiPNG.rb '🐧'a50026'
../createEmojiPNG.rb '🍎'a50026'
../createEmojiPNG.rb '❓' 'a50026'
```

## How to create emoji PNGs

* The following creates: `x2753-BLACK-QUESTION-MARK-ORNAMENT-a50026.png` with colour `#a50026` with the background colour of hex `a50026` which is red-ish.
```bash
cd EMOJI_PNG
./createEmojiPNG.rb '❓' 'a50026'
``` 