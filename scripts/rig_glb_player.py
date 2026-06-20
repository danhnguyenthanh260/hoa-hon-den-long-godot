# R1 — Auto-rig GIẢI PHẪU cho player từ mesh A-pose (AI sinh).
# Khác bản heuristic cũ: khớp đặt theo MỐC giải phẫu (Loomis/Unity Humanoid),
# thêm Neck + Toe, khuỷu/cổ tay theo tỉ lệ đúng dọc trục tay A-pose. Skin theo
# "đoạn-xương gần nhất" (2 ảnh hưởng/đỉnh) tự bám theo vị trí khớp mới.
# Mốc %H (từ chân lên): vai 0.81 · ngực 0.72 · cổ 0.82 · đầu 0.88 · hông 0.52
#   gối 0.27 · cổ chân 0.05 ; khuỷu = 0.45 dọc vai→ngón, cổ tay = 0.82.
# Dùng: python scripts/rig_glb_player.py <vao.glb> <ra.glb>
import sys

import numpy as np
import trimesh
from pygltflib import (
    GLTF2, Buffer, BufferView, Accessor, Mesh as GMesh, Primitive, Node, Scene,
    Skin, Attributes, ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER, FLOAT, UNSIGNED_BYTE,
    UNSIGNED_INT, SCALAR, VEC3, VEC4, MAT4,
)

SRC = sys.argv[1] if len(sys.argv) > 1 else "assets/models/minh_apose_0.glb"
DST = sys.argv[2] if len(sys.argv) > 2 else "assets/models/minh_player_rigged.glb"

scene = trimesh.load(SRC, force="scene")
mesh = trimesh.util.concatenate([g for g in scene.geometry.values()])
V = np.asarray(mesh.vertices, dtype=np.float32)
F = np.asarray(mesh.faces, dtype=np.uint32)
N = np.asarray(mesh.vertex_normals, dtype=np.float32)
print(f"dinh: {len(V)}, mat: {len(F)}")

lo = V.min(axis=0)
hi = V.max(axis=0)
H = hi[1] - lo[1]
W = hi[0] - lo[0]
y01 = (V[:, 1] - lo[1]) / H
cx = (lo[0] + hi[0]) / 2.0
mid_z = float(V[:, 2].mean())


def P(t, x=None, z=None):  # mốc theo tỉ lệ cao t; mặc định ở tim người
    return np.array([cx if x is None else x, lo[1] + t * H, mid_z if z is None else z],
                    dtype=np.float32)


# tâm hai chân từ đỉnh thấp
low = V[(y01 > 0.05) & (y01 < 0.35)]
left_x = float(low[low[:, 0] < cx][:, 0].mean())
right_x = float(low[low[:, 0] >= cx][:, 0].mean())
# mũi chân: z trước nhất của khối bàn chân
footv = V[y01 < 0.10]
front_z = float(np.percentile(footv[:, 2], 90)) if len(footv) else mid_z

# tay A-pose: ngón = đỉnh xa tâm nhất mỗi phía; vai theo bề ngang chuẩn;
# khuỷu/cổ tay theo tỉ lệ dọc trục vai→ngón.
upper = V[y01 > 0.45]


def arm(sign):
    side = upper[(upper[:, 0] * sign) > (cx * sign)]
    if len(side) < 10:
        tip = np.array([cx + sign * 0.42 * W, lo[1] + 0.55 * H, mid_z], dtype=np.float32)
    else:
        tip = side[np.argmax(np.abs(side[:, 0] - cx))].astype(np.float32)
        tip[2] = mid_z
    shoulder = np.array([cx + sign * 0.18 * W, lo[1] + 0.81 * H, mid_z], dtype=np.float32)
    elbow = shoulder + 0.45 * (tip - shoulder)
    wrist = shoulder + 0.82 * (tip - shoulder)
    return shoulder, elbow, wrist


shL, elL, wrL = arm(-1.0)
shR, elR, wrR = arm(+1.0)
print("vai L/R:", np.round(shL, 3), np.round(shR, 3))
print("co tay L/R:", np.round(wrL, 3), np.round(wrR, 3))

# (ten, cha, vi tri goc xuong) — thu tu cha luon dung truoc con
BONES = [
    ("hips",     -1, P(0.52)),                       # 0
    ("spine",     0, P(0.60)),                       # 1
    ("chest",     1, P(0.72)),                       # 2
    ("neck",      2, P(0.82)),                       # 3  (MOI)
    ("head",      3, P(0.88)),                       # 4
    ("clavicleL", 2, P(0.82, cx - 0.06 * W)),        # 5
    ("upperarmL", 5, shL),                           # 6
    ("forearmL",  6, elL),                           # 7
    ("handL",     7, wrL),                           # 8
    ("clavicleR", 2, P(0.82, cx + 0.06 * W)),        # 9
    ("upperarmR", 9, shR),                           # 10
    ("forearmR", 10, elR),                           # 11
    ("handR",    11, wrR),                           # 12
    ("thighL",    0, P(0.50, left_x)),               # 13
    ("shinL",    13, P(0.27, left_x)),               # 14
    ("footL",    14, P(0.05, left_x)),               # 15
    ("toeL",     15, P(0.02, left_x, front_z)),      # 16 (MOI)
    ("thighR",    0, P(0.50, right_x)),              # 17
    ("shinR",    17, P(0.27, right_x)),              # 18
    ("footR",    18, P(0.05, right_x)),              # 19
    ("toeR",     19, P(0.02, right_x, front_z)),     # 20 (MOI)
]
NB = len(BONES)
heads = np.stack([b[2] for b in BONES]).astype(np.float32)

# doan xuong = goc xuong -> trung binh goc cac xuong con (la xuong: noi dai)
child_of = {}
for bi, (_, p, _) in enumerate(BONES):
    if p >= 0:
        child_of.setdefault(p, []).append(bi)
seg_a = np.zeros((NB, 3), dtype=np.float32)
seg_b = np.zeros((NB, 3), dtype=np.float32)
for bi, (_, p, h) in enumerate(BONES):
    seg_a[bi] = h
    kids = child_of.get(bi, [])
    if kids:
        seg_b[bi] = np.mean([heads[k] for k in kids], axis=0)
    elif p >= 0:
        seg_b[bi] = h + (h - heads[p]) * 0.8
    else:
        seg_b[bi] = h + np.array([0, 0.1 * H, 0], dtype=np.float32)


def pt_seg_dist(pts, a, b):
    ab = b - a
    L2 = float(ab @ ab) + 1e-9
    t = np.clip(((pts - a) @ ab) / L2, 0.0, 1.0)
    proj = a + np.outer(t, ab)
    return np.linalg.norm(pts - proj, axis=1)


D = np.stack([pt_seg_dist(V, seg_a[bi], seg_b[bi]) for bi in range(NB)], axis=1)
order = np.argsort(D, axis=1)
joints = np.zeros((len(V), 4), dtype=np.uint8)
weights = np.zeros((len(V), 4), dtype=np.float32)
j0 = order[:, 0]
j1 = order[:, 1]
d0 = np.take_along_axis(D, order[:, :1], axis=1)[:, 0] + 1e-5
d1 = np.take_along_axis(D, order[:, 1:2], axis=1)[:, 0] + 1e-5
w0 = 1.0 / d0
w1 = (1.0 / d1) * ((d0 / d1) ** 2)     # mềm: xương 2 xa hơn nhiều -> gần như 100% xương 1
s = w0 + w1
joints[:, 0] = j0.astype(np.uint8)
joints[:, 1] = j1.astype(np.uint8)
weights[:, 0] = w0 / s
weights[:, 1] = w1 / s
print("xuong:", NB, "| verts gan tay (>=upperarm):",
      int(((joints[:, 0] >= 6) & (joints[:, 0] <= 12) & (weights[:, 0] > 0.5)).sum()))

# vertex colors neu co
COL = None
vc = getattr(mesh.visual, "vertex_colors", None)
if vc is not None and len(vc) == len(V):
    COL = (np.asarray(vc, dtype=np.float32) / 255.0).astype(np.float32)
    print("giu vertex colors:", COL.shape)

# ---- ghi glb ----
ibms = []
for _, _, head in BONES:
    m = np.identity(4, dtype=np.float32)
    m[3, 0:3] = -head
    ibms.append(m)

bin_data = b""
views = []


def add_view(data, target=None):
    global bin_data
    off = len(bin_data)
    views.append(BufferView(buffer=0, byteOffset=off, byteLength=len(data), target=target))
    bin_data += data + b"\x00" * ((4 - len(data) % 4) % 4)
    return len(views) - 1


v_pos = add_view(V.tobytes(), ARRAY_BUFFER)
v_nor = add_view(N.tobytes(), ARRAY_BUFFER)
v_joi = add_view(joints.tobytes(), ARRAY_BUFFER)
v_wei = add_view(weights.tobytes(), ARRAY_BUFFER)
v_idx = add_view(F.reshape(-1).tobytes(), ELEMENT_ARRAY_BUFFER)
v_ibm = add_view(np.stack(ibms).tobytes())
v_col = add_view(COL.tobytes(), ARRAY_BUFFER) if COL is not None else None

acc = [
    Accessor(bufferView=v_pos, componentType=FLOAT, count=len(V), type=VEC3,
             min=lo.tolist(), max=hi.tolist()),
    Accessor(bufferView=v_nor, componentType=FLOAT, count=len(V), type=VEC3),
    Accessor(bufferView=v_joi, componentType=UNSIGNED_BYTE, count=len(V), type=VEC4),
    Accessor(bufferView=v_wei, componentType=FLOAT, count=len(V), type=VEC4),
    Accessor(bufferView=v_idx, componentType=UNSIGNED_INT, count=F.size, type=SCALAR),
    Accessor(bufferView=v_ibm, componentType=FLOAT, count=NB, type=MAT4),
]
attrs = Attributes(POSITION=0, NORMAL=1, JOINTS_0=2, WEIGHTS_0=3)
if v_col is not None:
    acc.append(Accessor(bufferView=v_col, componentType=FLOAT, count=len(V), type=VEC4))
    attrs.COLOR_0 = len(acc) - 1

nodes = []
for bi, (name, parent, head) in enumerate(BONES):
    local = head - (BONES[parent][2] if parent >= 0 else np.zeros(3, dtype=np.float32))
    nodes.append(Node(name=name, translation=[float(local[0]), float(local[1]), float(local[2])],
                      children=[i for i, (_, p, _) in enumerate(BONES) if p == bi] or None))
nodes.append(Node(name="MinhMesh", mesh=0, skin=0))

gltf = GLTF2(
    scenes=[Scene(nodes=[0, NB])],
    scene=0,
    nodes=nodes,
    meshes=[GMesh(primitives=[Primitive(attributes=attrs, indices=4)])],
    skins=[Skin(joints=list(range(NB)), inverseBindMatrices=5, skeleton=0)],
    bufferViews=views,
    accessors=acc,
    buffers=[Buffer(byteLength=len(bin_data))],
)
gltf.set_binary_blob(bin_data)
gltf.save(DST)
print("DONE:", DST, "| xuong:", NB)
