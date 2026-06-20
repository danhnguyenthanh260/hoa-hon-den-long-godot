# Auto-rig mesh người A-pose (AI sinh) thành glb player có khung xương ĐẦY ĐỦ TAY.
# Khác rig_glb.py (rig ghost 10 xương không tay): bản này thêm vai/cánh/cẳng tay L-R
# và skin theo "đoạn-xương gần nhất" (2 ảnh hưởng / đỉnh, trọng số theo nghịch đảo
# khoảng cách) — bền hơn band-y thủ công cho mesh tùy ý.
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


def P(x, t, z=None):
    return np.array([x, lo[1] + t * H, mid_z if z is None else z], dtype=np.float32)


# tâm hai chân: trung bình x của đỉnh thấp theo phía
low = V[(y01 > 0.05) & (y01 < 0.35)]
left_x = float(low[low[:, 0] < cx][:, 0].mean())
right_x = float(low[low[:, 0] >= cx][:, 0].mean())

# vai + tay (A-pose: tay dang xuống-ngoài). Lấy cụm đỉnh trên-ngoài mỗi phía.
upper = y01 > 0.55
torso_half = 0.16 * W            # nửa bề ngang thân (ước lượng)
armL_mask = upper & (V[:, 0] < cx - torso_half)
armR_mask = upper & (V[:, 0] > cx + torso_half)


def arm_points(mask, sign):
    pts = V[mask]
    if len(pts) < 10:                       # không tách được tay -> đặt mặc định
        sx = cx + sign * torso_half
        return (P(sx, 0.80), P(cx + sign * 0.32 * W, 0.68),
                P(cx + sign * 0.42 * W, 0.55))
    # bàn tay = đỉnh xa tâm nhất; vai = gần thân & cao
    tip = pts[np.argmax(np.abs(pts[:, 0] - cx))]
    sh_y = lo[1] + 0.80 * H
    shoulder = np.array([cx + sign * torso_half, sh_y, mid_z], dtype=np.float32)
    hand = np.array([tip[0], tip[1], mid_z], dtype=np.float32)
    elbow = (shoulder + hand) / 2.0
    return shoulder, elbow, hand


shL, elL, haL = arm_points(armL_mask, -1.0)
shR, elR, haR = arm_points(armR_mask, +1.0)
print("vai L/R:", np.round(shL, 3), np.round(shR, 3))
print("tay L/R verts:", int(armL_mask.sum()), int(armR_mask.sum()))

# (ten, cha, vi tri goc xuong)
BONES = [
    ("hips",   -1, P(cx, 0.52)),         # 0
    ("spine",   0, P(cx, 0.62)),         # 1
    ("chest",   1, P(cx, 0.74)),         # 2
    ("head",    2, P(cx, 0.88)),         # 3
    ("thighL",  0, P(left_x, 0.50)),     # 4
    ("shinL",   4, P(left_x, 0.27)),     # 5
    ("footL",   5, P(left_x, 0.05)),     # 6
    ("thighR",  0, P(right_x, 0.50)),    # 7
    ("shinR",   7, P(right_x, 0.27)),    # 8
    ("footR",   8, P(right_x, 0.05)),    # 9
    ("clavL",   2, P(cx - 0.06 * W, 0.82)),  # 10
    ("upperarmL", 10, shL),              # 11
    ("forearmL", 11, elL),               # 12
    ("handL",   12, haL),                # 13
    ("clavR",   2, P(cx + 0.06 * W, 0.82)),  # 14
    ("upperarmR", 14, shR),              # 15
    ("forearmR", 15, elR),               # 16
    ("handR",   16, haR),                # 17
]
NB = len(BONES)
heads = np.stack([b[2] for b in BONES]).astype(np.float32)

# doan xuong = tu goc xuong -> goc xuong con (la xuong: keo dai theo huong cha->no)
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
    elif p >= 0:                              # la xuong: noi dai theo huong cha->no
        seg_b[bi] = h + (h - heads[p]) * 0.8
    else:
        seg_b[bi] = h + np.array([0, 0.1 * H, 0], dtype=np.float32)


def pt_seg_dist(pts, a, b):
    ab = b - a
    L2 = float(ab @ ab) + 1e-9
    t = np.clip(((pts - a) @ ab) / L2, 0.0, 1.0)
    proj = a + np.outer(t, ab)
    return np.linalg.norm(pts - proj, axis=1)


# khoang cach den moi doan xuong -> chon 2 gan nhat, trong so nghich dao kc
D = np.stack([pt_seg_dist(V, seg_a[bi], seg_b[bi]) for bi in range(NB)], axis=1)
order = np.argsort(D, axis=1)
joints = np.zeros((len(V), 4), dtype=np.uint8)
weights = np.zeros((len(V), 4), dtype=np.float32)
j0 = order[:, 0]
j1 = order[:, 1]
d0 = np.take_along_axis(D, order[:, :1], axis=1)[:, 0] + 1e-5
d1 = np.take_along_axis(D, order[:, 1:2], axis=1)[:, 0] + 1e-5
w0 = (1.0 / d0)
w1 = (1.0 / d1)
# lam mem: neu xuong thu 2 xa hon nhieu thi gan nhu 100% xuong 1
ratio = (d0 / d1)
w1 = w1 * (ratio ** 2)
s = w0 + w1
joints[:, 0] = j0.astype(np.uint8)
joints[:, 1] = j1.astype(np.uint8)
weights[:, 0] = w0 / s
weights[:, 1] = w1 / s
print("verts gan vao tay (bone>=11):",
      int(((joints[:, 0] >= 11) & (weights[:, 0] > 0.5)).sum()))

# vertex colors neu co (ColorVisuals)
COL = None
vis = mesh.visual
vc = getattr(vis, "vertex_colors", None)
if vc is not None and len(vc) == len(V):
    COL = (np.asarray(vc, dtype=np.float32) / 255.0).astype(np.float32)
    print("giu vertex colors:", COL.shape)


# ---- ghi glb co skin ----
pos_b = V.tobytes()
nor_b = N.tobytes()
idx_b = F.reshape(-1).tobytes()
joi_b = joints.tobytes()
wei_b = weights.tobytes()
col_b = COL.tobytes() if COL is not None else None

ibms = []
for name, parent, head in BONES:
    m = np.identity(4, dtype=np.float32)
    m[3, 0:3] = -head
    ibms.append(m)
ibm_b = np.stack(ibms).tobytes()

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
v_col = add_view(col_b, ARRAY_BUFFER) if col_b is not None else None

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
