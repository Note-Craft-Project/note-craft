import base64
import re
import os

svg_path = r'd:\Dev\Notecraft Workspace\resource\design\metronome\metronome.svg'
output_path = r'assets\images\metronome_icon.png'

with open(svg_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Match the base64 data
match = re.search(r'data:image/png;base64,([^"]+)', content)
if match:
    img_data = base64.b64decode(match.group(1))
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(img_data)
    print("Success")
else:
    print("Base64 not found")
