"""A continuous draped changeling sculpt; preserves the player's physics."""
import sculpt_creatures as sculpt
parts = [(0,.27,0,.65,.58,.47),(0,-.43,0,.37,.45,.30),
         (-.35,-.34,.05,.18,.28,.20),(.35,-.34,.05,.18,.28,.20)]
for x in [-.28,0,.28]:
    parts.append((x,-.85,.04,.19,.15,.28))
sculpt.bake('Wandering Changeling',parts_override=parts,step=.052,
            painter=lambda p,n: [.87,.89,.84,1])
