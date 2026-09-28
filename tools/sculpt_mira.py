"""Bake only the premium Mira asset. Other NPC assets are never rewritten."""
import sculpt_creatures as sculpt

parts = [(0,-.49,0,.34,.43,.29), (0,.28,0,.65,.57,.46),
         (-.37,.14,.21,.30,.29,.32),(.37,.14,.21,.30,.32,.32),
         (-.14,.06,.44,.21,.16,.18),(.14,.06,.44,.21,.16,.18),
         (0,.19,.44,.16,.19,.18)]
for s in [-1,1]:
    parts += [(s*.38,-.35,.04,.14,.29,.16),
              (s*.43,-.51,.17,.18,.14,.19),
              (s*.21,-.86,.12,.18,.14,.27)]
    for dx in [-.075,0,.075]:
        parts += [(s*.21+dx,-.86,.30,.065,.09,.11),
                  (s*.43+dx,-.51,.29,.055,.085,.07)]
# A continuous curled fox tail, attached to the pelvis and tucked to one side.
parts += [(.23,-.66,-.23,.22,.21,.25),(.45,-.68,-.25,.28,.22,.26),
          (.65,-.55,-.23,.27,.29,.26),(.73,-.31,-.22,.22,.28,.23),
          (.67,-.09,-.21,.18,.22,.19)]

base_field = sculpt.field
def fox_field(p, recipe):
    d = base_field(p, recipe)
    x,y,z = p
    for side in [-1,1]:
        t = max(0,min(1,(y-.53)/.70))
        width = .22*(1-t)
        ear = max(abs(x-(side*.43+side*.06*t))-width,
                  .53-y, y-1.23, abs(z+.02)-(.15-.065*t))-.018
        h = max(.09-abs(d-ear),0)/.09
        d = min(d,ear)-h*h*.09*.25
    return d
sculpt.field = fox_field

def pigment(p,n):
    x,y,z=p
    fur=[.77,.39,.25,1]
    if z>.26 and y<.25 and abs(x)<.47: fur=[1,.88,.68,1]
    if y>.67 and z>.045 and abs(abs(x)-(.43+.06*(y-.53)/.70))<.13*(1-(y-.53)/.70):
        fur=[.82,.46,.45,1]
    if x>.55 and y>-.26: fur=[.96,.83,.65,1]
    if y<-.79 or (y<-.43 and z>.19 and abs(x)>.30): fur=[.96,.76,.52,1]
    if z>.32 and -.04<y<.30 and abs(x)>.36: fur=[.91,.48,.42,1]
    return fur

sculpt.bake('Mira Premium', parts_override=parts, step=.038, painter=pigment)
