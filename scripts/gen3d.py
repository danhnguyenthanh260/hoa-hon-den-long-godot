# Sinh mesh 3D có texture từ ảnh nhân vật qua HF Space Hunyuan3D-2.
# Dùng: python scripts/gen3d.py <ảnh vào> <thư mục ra>
import sys
import shutil
from pathlib import Path

from gradio_client import Client, handle_file

IMG = sys.argv[1] if len(sys.argv) > 1 else "shots/chara/input-crop.png"
OUT = Path(sys.argv[2] if len(sys.argv) > 2 else "assets/models")
TAG = sys.argv[3] if len(sys.argv) > 3 else "minh_shape"
OUT.mkdir(parents=True, exist_ok=True)


def save_meshes(result, tag):
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
        dest = OUT / f"{tag}_{i}{Path(f).suffix}"
        shutil.copy(f, dest)
        print("LUU:", dest, flush=True)
    return bool(found)


def try_hunyuan_shape():
    print("=== tencent/Hunyuan3D-2 /shape_generation ===", flush=True)
    client = Client("tencent/Hunyuan3D-2")
    result = client.predict(
        caption="",
        image=handle_file(IMG),
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
    return save_meshes(result, TAG)


def try_trellis():
    print("=== JeffreyXiang/TRELLIS ===", flush=True)
    client = Client("JeffreyXiang/TRELLIS")
    client.predict(api_name="/start_session")
    processed = client.predict(image=handle_file(IMG), api_name="/preprocess_image")
    print("preprocess xong", flush=True)
    client.predict(
        image=processed,
        multiimages=[],
        seed=1,
        ss_guidance_strength=7.5,
        ss_sampling_steps=12,
        slat_guidance_strength=3.0,
        slat_sampling_steps=12,
        multiimage_algo="stochastic",
        api_name="/image_to_3d",
    )
    print("image_to_3d xong", flush=True)
    result = client.predict(mesh_simplify=0.95, texture_size=1024, api_name="/extract_glb")
    return save_meshes(result, "minh_trellis")


def main():
    for fn in (try_hunyuan_shape, try_trellis):
        try:
            if fn():
                print("DONE", flush=True)
                return
        except Exception as e:
            print(f"LOI: {type(e).__name__}: {e}", flush=True)
    print("FAILED", flush=True)


if __name__ == "__main__":
    main()
