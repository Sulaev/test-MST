
with open(lib/screens/animal_detail_screen.dart, r, encoding=utf-8) as f:
    lines = f.readlines()

has_import = any(favorites_service in line for line in lines)
if not has_import:
    lines.insert(3, import
