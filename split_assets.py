from pathlib import Path
p = Path('index.html')
text = p.read_text(encoding='utf-8')
style_start = text.find('<style>')
style_end = text.find('</style>', style_start)
if style_start == -1 or style_end == -1:
    raise SystemExit('Style block not found')
style_content = text[style_start + len('<style>'):style_end]
script_positions = []
idx = 0
while True:
    start = text.find('<script>', idx)
    if start == -1:
        break
    end = text.find('</script>', start)
    if end == -1:
        raise SystemExit('Script end tag missing')
    script_positions.append((start, end + len('</script>')))
    idx = end + len('</script>')
script_content = '\n\n'.join(text[s + len('<script>'):e - len('</script>')] for s, e in script_positions)
Path('styles.css').write_text(style_content.strip() + '\n', encoding='utf-8')
Path('script.js').write_text(script_content.strip() + '\n', encoding='utf-8')
new_text = text[:style_start] + '  <link rel="stylesheet" href="styles.css">\n' + text[style_end + len('</style>'):]
for start, end in reversed(script_positions):
    new_text = new_text[:start] + new_text[end:]
body_close = new_text.rfind('</body>')
if body_close == -1:
    raise SystemExit('No </body> found')
new_text = new_text[:body_close] + '  <script src="script.js"></script>\n' + new_text[body_close:]
Path('index.html').write_text(new_text, encoding='utf-8')
print('done')
