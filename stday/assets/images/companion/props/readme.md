# Companion props naming

Place PNG files in category folders. The app maps story content to prop images by file name.

Category folders:

- `study/`
- `sport/`
- `friend/`
- `family/`
- `hobby/`
- `other/`

The app tries exact and partial word matches first. If no matching image exists for the current story/detail/note token, it picks one stable candidate from the matching category folder.

File names may be English. The matcher splits names by `-`, `_`, spaces, and other separators.

Examples:

- `study/identification-card.png` can match `identification`, `card`, `身份证`, `学生证`, or `证件`.
- `study/calculator.png` can match `calculator`, `数学`, or `计算器`.
- `sport/water-bottle.png` can match `water`, `bottle`, `喝水`, or `水瓶`.

Recommended:

- PNG with transparent background
- Square canvas
- Keep the main object centered with transparent padding
- Do not use `/ \ : * ? " < > | .` in the file stem
