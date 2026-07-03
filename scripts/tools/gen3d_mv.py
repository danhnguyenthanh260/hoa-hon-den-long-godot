# Multiview image->3D qua Hunyuan3D-2: front lam anh chinh + 3 view phu (back/left/right)
# de gen co chieu sau -> tach tay khoi than tot hon 1-view.
import sys, shutil
from pathlib import Path
from gradio_client import Client, handle_file
C = "shots/chara"
OUT = Path("assets/models"); OUT.mkdir(parents=True, exist_ok=True)
TAG = sys.argv[1] if len(sys.argv) > 1 else "minh_mv"
cl = Client("tencent/Hunyuan3D-2")
res = cl.predict(
    caption="",
    image=handle_file(f"{C}/apose_front.png"),
    mv_image_front=handle_file(f"{C}/apose_front.png"),
    mv_image_back=handle_file(f"{C}/apose_back.png"),
    mv_image_left=handle_file(f"{C}/apose_left.png"),
    mv_image_right=handle_file(f"{C}/apose_right.png"),
    steps=30, guidance_scale=5.0, seed=1234, octree_resolution=256,
    check_box_rembg=True, num_chunks=8000, randomize_seed=False,
    api_name="/shape_generation",
)
found = []
def walk(x):
    if isinstance(x, str) and Path(x).suffix.lower() in (".glb",".obj",".gltf"): found.append(x)
    elif isinstance(x, dict):
        for v in x.values(): walk(v)
    elif isinstance(x, (list, tuple)):
        for v in x: walk(v)
walk(res)
for i,f in enumerate(found):
    d = OUT / f"{TAG}_{i}{Path(f).suffix}"; shutil.copy(f, d); print("LUU:", d, flush=True)
print("DONE" if found else "FAILED", flush=True)
