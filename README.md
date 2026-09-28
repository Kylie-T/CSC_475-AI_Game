# The Midnight Market Exchange

A Godot 4 3D cozy fantasy market about introducing neighbors, helping them trade, and ending the evening together at the fountain.

## Run

1. Import `project.godot` in Godot 4.
2. Press **Play Project**.
3. Move with **WASD** and talk or direct vendors with **E**.

## Detailed storybook visuals

All sixteen market residents and the player have opaque sculpted bodies, detailed eyes with irises, pupils and catchlights, tiny paws or draped feet, fitted layered clothing, stitched trim, and personal accessories. The six story vendors retain their distinct species: Mira the Moss Fox, Pip the Moon Moth, Juniper the Pebble Golem, Bramble the Forest Dragon, Cloud the Star Sprite, and Tula the Leaf Deer. Their original roles, needs, locations, interactions, collisions and movement behavior remain intact.

All nine market stalls use Mira's quality standard: beveled individual counter planks, carved botanical trim and pillars, folded striped canvas with seams and scallops, woven baskets, flowers, framed golden lanterns and sculpted product plaques below the characters' faces. No 3D lettering remains on stalls, buildings or the ground; character names and clues appear in the screen UI. Each shop has its own merchandise geometry, including spotted mushrooms, glazed bottles and charms, sculpted teapots and cups, scored bread, rain jars, maps and compasses, shell buttons and ribbons, or paper moons. Higher, smaller canopies fade when camera rays to character heads and shoulders pass through them.

Buildings on the two boundary rows use the supplied Cozy Neutrals palette: cream, oatmeal, taupe, sage, dusty rose, muted blue and charcoal. Nine different building footprints and several heights create a varied skyline. Original wall height 4.2 is the minimum; complete buildings also exceed the original 5.7 overall height. Every visible architectural element fits within the 36 by 24 map, with gaps between neighboring building footprints and clearance at the shared corner. Sculpted plaster relief, timber braces and pegs, stone foundations, arched plank doors, recessed glowing windows, deep sills and flower boxes, layered slate shingles, ridge caps, chimneys and copper downpipes add architectural depth.

The ground has irregular chamfered cobblestones, gently worn crowns, variable stone sizes and corner shapes, real gaps over darker earth mortar and sparse low moss that shows through the joints. Materials use restrained clean colors and broad plaster variation, without noise textures. Warm lantern pools sit within blue-purple nighttime light and shared soft moon shadows. Small details use fewer polygons, and static geometry is batched by material; cobblestones use MultiMesh instances to keep rendering practical.

## Trading puzzle

Six story vendors form exactly three exclusive trading pairs. Each vendor sells something another needs and needs that neighbor's wares in return. Completed vendors cannot be reused. Ambient stallkeepers and shoppers remain friendly visitors outside the matching puzzle.

- Press **E** to ask an unfamiliar vendor about their wares and needs. The clue is saved in **Vendor Notes**.
- Press **E** again near a known vendor to choose them for an introduction.
- Visit another known vendor and press **E** to try the pair. Ask unfamiliar neighbors for their clue first.
- A wrong guess doesn't move or lock either vendor, and keeps your first choice selected. Press **E** near that chosen vendor to cancel.
- Correct partners walk toward their meeting positions while facing their walking direction, then face each other for a warm three-line conversation.
- Both return to their own stalls and original standing poses. Progress records each successful pair once.
- Find all three pairs and all six clues, and discover the fountain for its one-time task. You can continue exploring after solving the puzzle.

Vendor movement updates in the fixed physics loop and limits the final step to avoid overshooting. Meeting positions stay on each vendor's home side even when chosen in reverse order. Orientation accounts for the sculpted visual's local rotation, so characters face forward rather than backward or sideways.

The production player movement, fixed three-quarter orthographic camera, shopper behavior and existing collision shapes remain unchanged. The fountain has no additional blocking collision, matching the original behavior.

## Storybook fountain

The central fountain now has a hollow carved stone basin, individual beveled coping stones, botanical relief, a fluted column, a curved upper petal bowl, a stone flower crown and copper flower heart. Glossy pools, fine ripple rings, connected curved water ribbons, small splash shapes and upward jets replace the old floating torus arcs. Supported garden lanterns, four flower planters and a restrained cool water glow match the architectural materials and warm night lighting.

## Verification and previews

Run `python tools/verify_gameplay_unchanged.py` to verify the preserved player movement, camera, shoppers, idle animation and NPC collision function fingerprints. The vendor matching and trade functions intentionally change for the puzzle.

Run `Godot --headless --path . --script tools/verify_market_upgrade.gd --quit-after 240` to check opaque detailed characters with species-specific shading, letter-free stalls, varied building heights and widths, complete geometry within map bounds, non-overlapping building footprints, cobblestone count, roof obstruction fading, the original camera configuration and introduction/trade state transitions. Run `Godot --headless --path . --script tools/verify_vendor_puzzle.gd --quit-after 1500` for all pair combinations, clue discovery, cancellation, incorrect guesses, completed-vendor reuse prevention, actual reversed-order walking and return paths, visual facing direction, short dialogue sequences, decorative rugs and plants, the enlarged illuminated fountain, and its separately unlocked final task.

Visual research for the latest environment pass used The Metropolitan Museum of Art's 19th-century Rabat carpet (bold pattern, distinctive palette and elongated format), its Islamic carpet publications, and Royal Horticultural Society guidance on large containers and layered “thriller, filler and spiller” planting. The resulting assets are original simplified 3D designs rather than replicas.

A graphical run of `tools/verify_visuals.gd` also saves:

- `tools/upgraded_market_preview.png`
- `tools/pip_stall_preview.png`
- `tools/architecture_cobbles_preview.png`
- `tools/detailed_fountain_preview.png`

Preview framing only changes the temporary verification scene; it does not change the production camera.

## Visual implementation

- `vendor_puzzle.gd`: reciprocal vendor clues and pair-specific warm conversations.
- `premium_fountain.gd`: carved stone profiles, coping, botanical relief, pools, jets and garden lanterns.
- `premium_residents.gd`: fitted character clothing, eye geometry and role-specific accessories.
- `premium_market.gd`: detailed stalls and individual shop inventories.
- `premium_forager.gd`: shared sculpted mesh helpers, materials, fabric, lanterns and static batching.
- `premium_town.gd`: boundary architecture, plaster relief and instanced irregular cobblestones.
- `assets/creatures/`: closed connected sculpt meshes formed by smooth implicit unions.

Rebuild the base NPC anatomy with `python tools/sculpt_creatures.py`, only Mira with `python tools/sculpt_mira.py`, or the player with `python tools/sculpt_wanderer.py`. These tools use only the Python standard library and never change gameplay.
