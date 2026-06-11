# Text-to-3D qua HF Space Hunyuan3D-2 (caption-only, không cần ảnh).
# Dùng: python scripts/gen3d_text.py "prompt" <thư mục ra> <tên file>
import sys
import shutil
from pathlib import Path

from gradio_client import Client

PROMPT = sys.argv[1] if len(sys.argv) > 1 else "a cat"
OUT = Path(sys.argv[2] if len(sys.argv) > 2 else "assets/models")
TAG = sys.argv[3] if len(sys.argv) > 3 else "text3d"
OUT.mkdir(parents=True, exist_ok=True)

client = Client("tencent/Hunyuan3D-2")
result = client.predict(
    caption=PROMPT,
    image=None,
    mv_image_front=None,
    mv_image_back=None,
    mv_image_left=None,
    mv_image_right=None,
    steps=30,
    guidance_scale=5.0,
    seed=1234,
    octree_resolution=256,
    check_box_rembg=True,
    num_chunks=8000,
    randomize_seed=False,
    api_name="/shape_generation",
)

found = []


def walk(x):
    if isinstance(x, str) and Path(x).suffix.lower() in (".glb", ".obj", ".gltf"):
        found.append(x)
    elif isinstance(x, dict):
        for v in x.values():
            walk(v)
    elif isinstance(x, (list, tuple)):
        for v in x:
            walk(v)


walk(result)
for i, f in enumerate(found):
    dest = OUT / f"{TAG}_{i}{Path(f).suffix}"
    shutil.copy(f, dest)
    print("LUU:", dest, flush=True)
print("DONE" if found else "FAILED", flush=True)
