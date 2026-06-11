# Auto-rig mesh người đứng (AI sinh) thành glb có khung xương + trọng số da.
# Heuristic: đặt xương theo tỷ lệ chiều cao + tâm hai chân đo từ phân bố đỉnh;
# gán trọng số theo dải y với vùng chuyển pha mượt. Đủ tốt cho nhân vật stylized.
# Dùng: python scripts/rig_glb.py <vào.glb> <ra.glb>
import sys
import struct

import numpy as np
import trimesh
from pygltflib import (
    GLTF2, Buffer, BufferView, Accessor, Mesh as GMesh, Primitive, Node, Scene,
    Skin, Attributes, ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER, FLOAT, UNSIGNED_BYTE,
    UNSIGNED_INT, SCALAR, VEC3, VEC4, MAT4,
)

SRC = sys.argv[1] if len(sys.argv) > 1 else "assets/models/minh_shape_0.glb"
DST = sys.argv[2] if len(sys.argv) > 2 else "assets/models/minh_rigged.glb"

scene = trimesh.load(SRC, force="scene")
mesh = trimesh.util.concatenate([g for g in scene.geometry.values()])
V = np.asarray(mesh.vertices, dtype=np.float32)
F = np.asarray(mesh.faces, dtype=np.uint32)
N = np.asarray(mesh.vertex_normals, dtype=np.float32)
print(f"dinh: {len(V)}, mat: {len(F)}")

lo = V.min(axis=0)
hi = V.max(axis=0)
H = hi[1] - lo[1]
y01 = (V[:, 1] - lo[1]) / H            # cao độ chuẩn hóa 0..1
cx = (lo[0] + hi[0]) / 2.0

# tâm hai chân: trung bình x của đỉnh thấp (0.05..0.35H) theo phía
low = V[(y01 > 0.05) & (y01 < 0.35)]
left_x = float(low[low[:, 0] < cx][:, 0].mean())
right_x = float(low[low[:, 0] >= cx][:, 0].mean())
mid_z = float(V[:, 2].mean())

def P(x, t):  # điểm xương: x tuyệt đối, t = tỷ lệ cao
    return np.array([x, lo[1] + t * H, mid_z], dtype=np.float32)

# (tên, cha, vị trí gốc xương)
BONES = [
    ("hips",   -1, P(cx, 0.52)),
    ("spine",   0, P(cx, 0.62)),
    ("chest",   1, P(cx, 0.74)),
    ("head",    2, P(cx, 0.86)),
    ("thighL",  0, P(left_x, 0.50)),
    ("shinL",   4, P(left_x, 0.27)),
    ("footL",   5, P(left_x, 0.05)),
    ("thighR",  0, P(right_x, 0.50)),
    ("shinR",   7, P(right_x, 0.27)),
    ("footR",   8, P(right_x, 0.05)),
]
NB = len(BONES)

# ---- trọng số: dải y, chân chia trái/phải theo x, chuyển pha mượt ----
joints = np.zeros((len(V), 4), dtype=np.uint8)
weights = np.zeros((len(V), 4), dtype=np.float32)

def smooth(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3 - 2 * t)

is_left = V[:, 0] < cx
thigh = np.where(is_left, 4, 7).astype(np.uint8)
shin = np.where(is_left, 5, 8).astype(np.uint8)
foot = np.where(is_left, 6, 9).astype(np.uint8)

# các mốc dải (theo y01) và xương tương ứng dưới->trên
b_foot_top, b_shin_top, b_thigh_top, b_hips_top, b_spine_top, b_chest_top = 0.12, 0.30, 0.50, 0.58, 0.68, 0.80
BLEND = 0.05

for i in range(len(V)):
    y = y01[i]
    if y < b_foot_top:
        a, b, t = foot[i], shin[i], smooth((y - (b_foot_top - BLEND)) / (2 * BLEND))
    elif y < b_shin_top:
        a, b, t = shin[i], thigh[i], smooth((y - (b_shin_top - BLEND)) / (2 * BLEND))
    elif y < b_thigh_top:
        a, b, t = thigh[i], 0, smooth((y - (b_thigh_top - BLEND)) / (2 * BLEND))
    elif y < b_hips_top:
        a, b, t = 0, 1, smooth((y - (b_hips_top - BLEND)) / (2 * BLEND))
    elif y < b_spine_top:
        a, b, t = 1, 2, smooth((y - (b_spine_top - BLEND)) / (2 * BLEND))
    elif y < b_chest_top:
        a, b, t = 2, 3, smooth((y - (b_chest_top - BLEND)) / (2 * BLEND))
    else:
        a, b, t = 3, 3, 0.0
    joints[i, 0], joints[i, 1] = a, b
    weights[i, 0], weights[i, 1] = 1.0 - t, t

# vùng háng: đỉnh gần tâm x ở dải đùi -> hòa 2 đùi để khỏi rách
hip_band = (y01 > 0.35) & (y01 < 0.50)
near_mid = np.abs(V[:, 0] - cx) < 0.06 * (hi[0] - lo[0])
mix = hip_band & near_mid
joints[mix, 0] = 4
joints[mix, 1] = 7
weights[mix, 0] = 0.5
weights[mix, 1] = 0.5

# ---- ghi glb có skin ----
def blob(arr):
    return arr.tobytes()

pos_b = blob(V)
nor_b = blob(N)
idx_b = blob(F.reshape(-1))
joi_b = blob(joints)
wei_b = blob(weights)

ibms = []
for name, parent, head in BONES:
    m = np.identity(4, dtype=np.float32)
    m[3, 0:3] = -head            # column-major: hàng cuối là translation
    ibms.append(m)
ibm_b = blob(np.stack(ibms))

bin_data = b""
views = []
def add_view(data, target=None):
    global bin_data
    off = len(bin_data)
    views.append(BufferView(buffer=0, byteOffset=off, byteLength=len(data), target=target))
    bin_data += data + b"\x00" * ((4 - len(data) % 4) % 4)
    return len(views) - 1

v_pos = add_view(pos_b, ARRAY_BUFFER)
v_nor = add_view(nor_b, ARRAY_BUFFER)
v_joi = add_view(joi_b, ARRAY_BUFFER)
v_wei = add_view(wei_b, ARRAY_BUFFER)
v_idx = add_view(idx_b, ELEMENT_ARRAY_BUFFER)
v_ibm = add_view(ibm_b)

acc = [
    Accessor(bufferView=v_pos, componentType=FLOAT, count=len(V), type=VEC3,
             min=lo.tolist(), max=hi.tolist()),
    Accessor(bufferView=v_nor, componentType=FLOAT, count=len(V), type=VEC3),
    Accessor(bufferView=v_joi, componentType=UNSIGNED_BYTE, count=len(V), type=VEC4),
    Accessor(bufferView=v_wei, componentType=FLOAT, count=len(V), type=VEC4),
    Accessor(bufferView=v_idx, componentType=UNSIGNED_INT, count=F.size, type=SCALAR),
    Accessor(bufferView=v_ibm, componentType=FLOAT, count=NB, type=MAT4),
]

# nodes: 0..NB-1 = xương, NB = mesh node
nodes = []
for bi, (name, parent, head) in enumerate(BONES):
    local = head - (BONES[parent][2] if parent >= 0 else np.zeros(3, dtype=np.float32))
    nodes.append(Node(name=name, translation=[float(local[0]), float(local[1]), float(local[2])],
                      children=[i for i, (_, p, _) in enumerate(BONES) if p == bi] or None))
mesh_node = Node(name="GhostMesh", mesh=0, skin=0)
nodes.append(mesh_node)

gltf = GLTF2(
    scenes=[Scene(nodes=[0, NB])],
    scene=0,
    nodes=nodes,
    meshes=[GMesh(primitives=[Primitive(
        attributes=Attributes(POSITION=0, NORMAL=1, JOINTS_0=2, WEIGHTS_0=3),
        indices=4)])],
    skins=[Skin(joints=list(range(NB)), inverseBindMatrices=5, skeleton=0)],
    bufferViews=views,
    accessors=acc,
    buffers=[Buffer(byteLength=len(bin_data))],
)
gltf.set_binary_blob(bin_data)
gltf.save(DST)
print("DONE:", DST)
