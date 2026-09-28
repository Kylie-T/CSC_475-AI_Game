"""Bake continuous, closed chibi surfaces; no primitive shells survive the union."""
import json, math
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'creatures'
OUT.mkdir(parents=True, exist_ok=True)
SPECIES = ['Moss Fox', 'Moon Moth', 'Pebble Golem', 'Forest Dragon', 'Star Sprite', 'Leaf Deer', 'Kobold', 'Salamander', 'Satyr', 'Frogfolk', 'Mothkin', 'Dryad', 'Trollkin', 'Halfling', 'Catfolk', 'Cyclops']

def recipe(name):
    # Local floor is -1: preserve the existing NPC transforms and physics.
    parts = [(0,-.48,0,.37,.48,.30), (0,.27,0,.66,.61,.49)]
    for s in [-1,1]:
        parts += [(s*.23,-.85,.13,.22,.16,.28), (s*.36,-.43,.02,.19,.29,.20)]
    if name in ['Moss Fox','Catfolk','Kobold']:
        for s in [-1,1]:
            parts += [(s*.43,.80,0,.22,.40,.22)]
        parts += [(0,.13,.40,.32,.22,.24), (.40,-.55,-.25,.38,.25,.39)]
    elif name in ['Moon Moth','Mothkin']:
        for s in [-1,1]:
            parts += [(s*.63,-.12,-.17,.50,.46,.17), (s*.56,-.52,-.13,.36,.27,.17), (s*.29,.85,0,.10,.32,.11), (s*.34,1.07,0,.14,.14,.14)]
    elif name == 'Pebble Golem':
        parts[1] = (0,.23,0,.77,.62,.53)
        parts += [(-.54,.63,-.07,.27,.25,.28),(.55,-.43,0,.27,.31,.26)]
    elif name in ['Forest Dragon','Salamander']:
        parts += [(0,.07,.40,.40,.26,.25),(0,-.58,-.36,.23,.22,.47)]
        for s in [-1,1]:
            parts += [(s*.44,.81,-.05,.16,.30,.17)]
            if name == 'Forest Dragon':
                parts += [(s*.56,-.22,-.19,.34,.32,.18)]
    elif name == 'Star Sprite':
        for x,y,rx,ry in [(0,.91,.21,.38),(-.64,.44,.35,.20),(.64,.44,.35,.20),(-.42,-.15,.26,.27),(.42,-.15,.26,.27)]:
            parts += [(x,y,0,rx,ry,.29)]
    elif name in ['Leaf Deer','Satyr']:
        for s in [-1,1]:
            parts += [(s*.60,.47,0,.31,.16,.20),(s*.34,.86,-.09,.12,.32,.13)]
            if name == 'Leaf Deer':
                parts += [(s*.48,1.04,-.08,.22,.11,.13),(s*.26,1.14,-.08,.11,.23,.12)]
    elif name == 'Frogfolk':
        parts += [(-.40,.72,.12,.25,.26,.25),(.40,.72,.12,.25,.26,.25)]
    elif name == 'Dryad':
        parts += [(0,.89,0,.19,.40,.17),(-.22,.88,0,.27,.16,.19)]
    elif name == 'Trollkin':
        for s in [-1,1]: parts += [(s*.65,.32,0,.29,.22,.22)]
    elif name == 'Halfling':
        parts += [(0,.73,-.06,.68,.25,.48)]
    elif name == 'Cyclops':
        parts += [(0,.86,-.04,.16,.29,.16)]
    return parts

def field(p, parts):
    d = 100
    for x,y,z,rx,ry,rz in parts:
        q = math.sqrt(((p[0]-x)/rx)**2+((p[1]-y)/ry)**2+((p[2]-z)/rz)**2)
        b = (q-1)*min(rx,ry,rz)
        h = max(.11-abs(d-b),0)/.11
        d = min(d,b)-h*h*.11*.25
    return d

def bake(name, parts_override=None, step=.065, painter=None):
    parts = parts_override if parts_override is not None else recipe(name)
    lo = (-1.3,-1.1,-1.05)
    dims = tuple(int(size / step) + 1 for size in (2.73, 2.60, 2.145))
    points = {}; values = {}
    for i in range(dims[0]):
        for j in range(dims[1]):
            for k in range(dims[2]):
                key=(i,j,k); p=tuple(lo[a]+key[a]*step for a in range(3))
                points[key]=p; values[key]=field(p,parts)
    vertices=[]; faces=[]; edges={}
    corners=[(0,0,0),(1,0,0),(1,1,0),(0,1,0),(0,0,1),(1,0,1),(1,1,1),(0,1,1)]
    tetra=[(0,5,1,6),(0,1,2,6),(0,2,3,6),(0,3,7,6),(0,7,4,6),(0,4,5,6)]
    def edge(a,b):
        key=tuple(sorted((a,b)))
        if key not in edges:
            t=values[a]/(values[a]-values[b]); p=tuple(points[a][n]+t*(points[b][n]-points[a][n]) for n in range(3))
            edges[key]=len(vertices); vertices.append(p)
        return edges[key]
    for i in range(dims[0]-1):
        for j in range(dims[1]-1):
            for k in range(dims[2]-1):
                cs=[(i+a,j+b,k+c) for a,b,c in corners]
                if all(values[c]>0 for c in cs) or all(values[c]<=0 for c in cs): continue
                for tet in tetra:
                    inside=[cs[n] for n in tet if values[cs[n]]<=0]; outside=[cs[n] for n in tet if values[cs[n]]>0]
                    if len(inside) in [1,3]:
                        aa,bb=(inside,outside) if len(inside)==1 else (outside,inside)
                        faces.append([edge(aa[0],b) for b in bb])
                    elif len(inside)==2:
                        a,b=inside; c,d=outside
                        ac,ad,bc,bd=edge(a,c),edge(a,d),edge(b,c),edge(b,d)
                        faces += [[ac,ad,bc],[ad,bd,bc]]
    normals=[]; colors=[]
    for p in vertices:
        e=.001
        g=[field(tuple(p[n]+(e if n==a else 0) for n in range(3)),parts)-field(tuple(p[n]-(e if n==a else 0) for n in range(3)),parts) for a in range(3)]
        length=math.sqrt(sum(v*v for v in g)); normals.append([v/length for v in g])
        x,y,z=p; col=[1,1,1,1]
        # Pigment lives on the sculpt surface, including eyes, blush and smile.
        if z>.30 and -.05<y<.70:
            eyes=[0] if name=='Cyclops' else [-.24,.24]
            if any(((x-ex)/.095)**2+((y-.38)/.125)**2<1 for ex in eyes): col=[.10,.075,.12,1]
            if any(((x-ex)/.030)**2+((y-.425)/.035)**2<1 for ex in eyes): col=[1,1,.94,1]
            if any(((x-ex)/.12)**2+((y-.15)/.065)**2<1 for ex in [-.40,.40]): col=[1,.55,.59,1]
            if abs(x)<.13 and abs(y-(.13+2.3*x*x))<.018: col=[.22,.12,.16,1]
        if y<-.20 and z>.20: col=[1,.89,.71,1]
        colors.append(painter(p, normals[-1]) if painter else col)
    for face in faces:
        a,b,c=[vertices[n] for n in face]
        ab=[b[n]-a[n] for n in range(3)]; ac=[c[n]-a[n] for n in range(3)]
        cross=[ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]]
        # Godot uses clockwise front faces.
        if sum(cross[n]*normals[face[0]][n] for n in range(3))>0: face.reverse()
    data={'vertices':vertices,'normals':normals,'colors':colors,'indices':[i for f in faces for i in f]}
    for key in ['vertices','normals','colors']:
        data[key] = [[round(value, 5) for value in row] for row in data[key]]
    (OUT/(name.lower().replace(' ','_')+'.json')).write_text(json.dumps(data,separators=(',',':')))
    print(name,len(vertices),len(faces),flush=True)

if __name__=='__main__':
    for species in SPECIES: bake(species)
